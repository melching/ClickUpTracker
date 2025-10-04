//
//  TaskSelectorView.swift
//  ClickUpTracker
//
//  View for selecting a ClickUp task and confirming time entry
//

import SwiftUI

struct TaskSelectorView: View {
    let elapsedTime: TimeInterval
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var taskCache = TaskCache.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var tasks: [ClickUpTask] = []
    @State private var selectedTask: ClickUpTask?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var description = ""
    @State private var trackingDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isBillable: Bool
    @State private var isSubmitting = false
    @State private var searchTask: Task<Void, Never>?
    @State private var showOnlyAssigned = false
    @State private var editableSegments: [EditableTimeSegment] = []
    
    // Helper struct for editable segments
    struct EditableTimeSegment: Identifiable {
        let id = UUID()
        var startTime: Date
        var endTime: Date
        
        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
    }
    
    init(elapsedTime: TimeInterval) {
        self.elapsedTime = elapsedTime
        let now = Date()
        _trackingDate = State(initialValue: now)
        _endTime = State(initialValue: now)
        _startTime = State(initialValue: now.addingTimeInterval(-elapsedTime))
        _isBillable = State(initialValue: SettingsManager.shared.billableByDefault)
        
        // Initialize editable segments from TimeTracker
        let tracker = TimeTracker.shared
        var segments: [EditableTimeSegment] = []
        
        // Add completed segments
        for segment in tracker.timeSegments {
            if let end = segment.endTime {
                segments.append(EditableTimeSegment(startTime: segment.startTime, endTime: end))
            }
        }
        
        // Add current segment if tracking
        if tracker.state == .tracking, let currentStart = tracker.currentSegmentStart {
            segments.append(EditableTimeSegment(startTime: currentStart, endTime: Date()))
        }
        
        // If no segments, create one from the elapsed time
        if segments.isEmpty && elapsedTime > 0 {
            segments.append(EditableTimeSegment(startTime: now.addingTimeInterval(-elapsedTime), endTime: now))
        }
        
        _editableSegments = State(initialValue: segments)
    }
    
    var totalDuration: TimeInterval {
        editableSegments.reduce(0) { $0 + $1.duration }
    }
    
    // Round and merge segments based on minimum time increment
    func processSegmentsForSubmission() -> [EditableTimeSegment] {
        let minimumDuration = SettingsManager.shared.minimumTimeIncrement.seconds
        
        // Step 1: Round each segment to minimum duration
        var roundedSegments = editableSegments.map { segment -> EditableTimeSegment in
            let duration = segment.duration
            
            // If duration is less than minimum, extend the end time
            if duration < minimumDuration {
                let newEndTime = segment.startTime.addingTimeInterval(minimumDuration)
                return EditableTimeSegment(startTime: segment.startTime, endTime: newEndTime)
            }
            
            // Otherwise, round up to nearest multiple of minimum duration
            let multiplier = ceil(duration / minimumDuration)
            let roundedDuration = multiplier * minimumDuration
            let newEndTime = segment.startTime.addingTimeInterval(roundedDuration)
            return EditableTimeSegment(startTime: segment.startTime, endTime: newEndTime)
        }
        
        // Step 2: Sort by start time
        roundedSegments.sort { $0.startTime < $1.startTime }
        
        // Step 3: Merge overlapping segments
        var mergedSegments: [EditableTimeSegment] = []
        
        for segment in roundedSegments {
            if mergedSegments.isEmpty {
                mergedSegments.append(segment)
            } else {
                let lastIndex = mergedSegments.count - 1
                let lastSegment = mergedSegments[lastIndex]
                
                // Check if segments overlap
                if segment.startTime <= lastSegment.endTime {
                    // Merge: extend the end time to the later of the two
                    let newEndTime = max(lastSegment.endTime, segment.endTime)
                    mergedSegments[lastIndex] = EditableTimeSegment(
                        startTime: lastSegment.startTime,
                        endTime: newEndTime
                    )
                } else {
                    // No overlap, add as new segment
                    mergedSegments.append(segment)
                }
            }
        }
        
        return mergedSegments
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assign Time to Task")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Time Entry Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Tracked")
                            .font(.headline)
                        
                        // Show all time segments
                        if !editableSegments.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(Array(editableSegments.enumerated()), id: \.offset) { index, segment in
                                    HStack(spacing: 12) {
                                        // Segment label
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .frame(width: 20)
                                        
                                        // Start time
                                        HStack(spacing: 4) {
                                            Text("Start:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            DatePicker("", selection: Binding(
                                                get: { editableSegments[index].startTime },
                                                set: { editableSegments[index].startTime = $0 }
                                            ), displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .controlSize(.small)
                                        }
                                        
                                        // End time
                                        HStack(spacing: 4) {
                                            Text("End:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            DatePicker("", selection: Binding(
                                                get: { editableSegments[index].endTime },
                                                set: { editableSegments[index].endTime = $0 }
                                            ), displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .controlSize(.small)
                                        }
                                        
                                        Spacer()
                                        
                                        // Duration
                                        Text(formatTime(segment.duration))
                                            .font(.system(.caption, design: .monospaced))
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        // Delete button
                                        Button(action: {
                                            editableSegments.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Delete segment")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.secondary.opacity(0.06))
                                    .cornerRadius(6)
                                }
                                
                                // Add segment button
                                Button(action: {
                                    let now = Date()
                                    let newSegment = EditableTimeSegment(
                                        startTime: now.addingTimeInterval(-3600),
                                        endTime: now
                                    )
                                    editableSegments.append(newSegment)
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Segment")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Divider()
                                
                                // Show processed segments (what will actually be submitted)
                                let processedSegments = processSegmentsForSubmission()
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        Text("Will Submit (\(SettingsManager.shared.minimumTimeIncrement.displayName) min):")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        ForEach(Array(processedSegments.enumerated()), id: \.offset) { index, segment in
                                            HStack(spacing: 8) {
                                                Text("\(index + 1).")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 20)
                                                
                                                Text(formatTimeRange(segment.startTime, segment.endTime))
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                Text(formatTime(segment.duration))
                                                    .font(.system(.caption, design: .monospaced))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.05))
                                            .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding(8)
                                .background(Color.green.opacity(0.08))
                                .cornerRadius(6)
                                
                                Divider()
                                
                                // Total duration
                                HStack {
                                    Text("Total Duration:")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatTime(processedSegments.reduce(0.0, { $0 + $1.duration })))
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Billable toggle
                        Toggle("Track as billable", isOn: $isBillable)
                            .padding(.horizontal)
                        
                        // Description (single line)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Add description...", text: $description)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Task Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Task")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Cache info and refresh button
                            HStack(spacing: 8) {
                                if taskCache.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 16, height: 16)
                                    Text("Loading \(taskCache.loadingProgress) tasks...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(taskCache.tasks.count) tasks cached")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("Updated: \(taskCache.lastUpdatedString())")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Button(action: {
                                    Task {
                                        await taskCache.refresh()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(taskCache.isLoading)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Start typing to search ClickUp tasks...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Toggle("Assigned to Me", isOn: $showOnlyAssigned)
                                    .toggleStyle(.checkbox)
                                    .controlSize(.small)
                                    .onChange(of: showOnlyAssigned) { oldValue, newValue in
                                        handleFilterChange()
                                    }
                            }
                            
                            // Search field (always visible)
                            TextField("Search tasks...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: searchText) { oldValue, newValue in
                                    performSearch(query: newValue)
                                }
                        }
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text("Searching...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding()
                        } else if let error = errorMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                Button("Retry") {
                                    performSearch(query: searchText)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        } else if searchText.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Type to search for tasks")
                                    .foregroundColor(.secondary)
                                Text("Minimum 2 characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if tasks.isEmpty && !isLoading {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No matching tasks found")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Found \(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if tasks.count >= 50 {
                                        Text("(showing first 50)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ScrollView {
                                    VStack(spacing: 8) {
                                        ForEach(tasks) { task in
                                            TaskRow(task: task, isSelected: selectedTask?.id == task.id)
                                                .onTapGesture {
                                                    selectedTask = task
                                                }
                                        }
                                    }
                                }
                                .frame(maxHeight: 300)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            // Footer with Submit button
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: submitTimeEntry) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(isSubmitting ? "Submitting..." : "Assign Time")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTask == nil || isSubmitting || totalDuration <= 0 || editableSegments.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 600, height: 600)
        .onAppear {
            // Refresh cache if needed on first appear
            if taskCache.tasks.isEmpty || taskCache.needsRefresh() {
                Task {
                    await taskCache.refresh()
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Clear tasks if search is too short
        if query.count < 2 {
            tasks = []
            selectedTask = nil
            errorMessage = nil
            return
        }
        
        // Debounce: wait 500ms before searching
        searchTask = Task {
            do {
                // Wait for debounce period
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                
                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    isLoading = true
                    errorMessage = nil
                }
                
                // Perform the search with optional assigned filter
                print("🔍 Searching for '\(query)' (assigned filter: \(showOnlyAssigned))")
                let searchResults: [ClickUpTask]
                if showOnlyAssigned {
                    searchResults = try await ClickUpAPI.shared.searchAssignedTasks(query: query)
                } else {
                    searchResults = try await ClickUpAPI.shared.searchTasks(query: query)
                }
                
                // Check if task was cancelled after API call
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    tasks = searchResults
                    isLoading = false
                    
                    // Clear selection if the selected task is not in results
                    if let selected = selectedTask, !searchResults.contains(where: { $0.id == selected.id }) {
                        selectedTask = nil
                    }
                    
                    let filterText = showOnlyAssigned ? " (assigned filter active)" : ""
                    print("✓ Found \(searchResults.count) tasks matching '\(query)'\(filterText)")
                }
            } catch is CancellationError {
                // Search was cancelled, do nothing
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleFilterChange() {
        // Re-trigger search with new filter if we have a search query
        if searchText.count >= 2 {
            performSearch(query: searchText)
        }
    }
    
    private func submitTimeEntry() {
        guard let task = selectedTask else { return }
        
        isSubmitting = true
        
        Task {
            do {
                // Process segments: round to minimum duration and merge overlapping
                let processedSegments = processSegmentsForSubmission()
                
                print("📊 Processed \(editableSegments.count) segments into \(processedSegments.count) merged segments")
                
                // Submit each processed segment as a separate time entry
                for segment in processedSegments {
                    guard segment.duration > 0 else { continue }
                    
                    print("⏱️ Submitting segment: \(segment.startTime) to \(segment.endTime) (\(segment.duration/60) minutes)")
                    
                    try await ClickUpAPI.shared.createTimeEntry(
                        taskID: task.id,
                        startTime: segment.startTime,
                        duration: segment.duration,
                        description: description.isEmpty ? nil : description,
                        billable: isBillable
                    )
                }
                
                await MainActor.run {
                    // Reset the time tracker
                    TimeTracker.shared.reset()
                    
                    // Cancel notifications
                    NotificationManager.shared.cancelTrackingReminders()
                    
                    // Update menu bar icon
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.updateMenuBarIcon()
                    }
                    
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit time entry: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    private func formatTimeRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct TaskRow: View {
    let task: ClickUpTask
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                HStack(spacing: 8) {
                    // Status badge - now more prominent
                    if let status = task.status {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor(for: status.color))
                                .frame(width: 8, height: 8)
                            Text(status.status)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: status.color).opacity(0.15))
                        .cornerRadius(6)
                    }
                    
                    if task.isMilestone == true {
                        Label("Milestone", systemImage: "flag.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                    
                    if let list = task.list {
                        Text(list.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Open in ClickUp button
            Button(action: {
                openTaskInClickUp()
            }) {
                Image(systemName: "arrow.up.forward.square")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("Open in ClickUp")
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func statusColor(for colorHex: String?) -> Color {
        guard let hex = colorHex else { return .gray }
        
        // Parse hex color (supports #RGB, #RRGGBB formats)
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    private func openTaskInClickUp() {
        // ClickUp task URL format: https://app.clickup.com/t/{task_id}
        if let url = URL(string: "https://app.clickup.com/t/\(task.id)") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct TaskSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        TaskSelectorView(elapsedTime: 3665)
    }
}
