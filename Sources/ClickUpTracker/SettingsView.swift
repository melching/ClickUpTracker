//
//  SettingsView.swift
//  ClickUpTracker
//
//  Settings interface for API configuration and preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingValidation = false
    @State private var validationMessage = ""
    @State private var isValidating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Form {
                Section(header: Text("ClickUp Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter your ClickUp API key", text: $settings.apiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        Link("Get your API key from ClickUp", destination: URL(string: "https://app.clickup.com/settings/apps")!)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter your Team ID", text: $settings.teamID)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Find your Team ID in the ClickUp URL when viewing your workspace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: validateCredentials) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            Text(isValidating ? "Validating..." : "Validate Credentials")
                        }
                    }
                    .disabled(settings.apiKey.isEmpty || settings.teamID.isEmpty || isValidating)
                }
                
                Section(header: Text("Notifications")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Frequency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Frequency", selection: $settings.notificationFrequency) {
                            ForEach(NotificationFrequency.allCases) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Get reminded while time tracking is active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Task Cache")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto-refresh task cache", isOn: $settings.autoRefreshEnabled)
                        
                        if settings.autoRefreshEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Refresh Interval")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Interval", selection: $settings.refreshIntervalMinutes) {
                                    ForEach(RefreshInterval.allCases) { interval in
                                        Text(interval.displayName).tag(interval)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Text("Tasks will be automatically refreshed at this interval")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cache Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(TaskCache.shared.tasks.count) tasks")
                                .font(.caption2)
                            Text("Last updated: \(TaskCache.shared.lastUpdatedString())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Clear Cache") {
                            TaskCache.shared.clear()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                Section(header: Text("Time Tracking")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Track time as billable by default", isOn: $settings.billableByDefault)
                        
                        Text("Time entries will be marked as billable unless you change it per entry")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Time Increment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minimum Time", selection: $settings.minimumTimeIncrement) {
                            ForEach(MinimumTimeIncrement.allCases) { increment in
                                Text(increment.displayName).tag(increment)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Each time segment will be rounded up to at least this duration to account for mental context switching")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Space Filtering")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter tasks by spaces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let availableSpaces = TaskCache.shared.getAvailableSpaces()
                        
                        if availableSpaces.isEmpty {
                            Text("No spaces found. Refresh the task cache to see available spaces.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(availableSpaces, id: \.id) { space in
                                    Toggle(space.name, isOn: Binding(
                                        get: { settings.selectedSpaceIDs.contains(space.id) },
                                        set: { isOn in
                                            if isOn {
                                                settings.selectedSpaceIDs.insert(space.id)
                                            } else {
                                                settings.selectedSpaceIDs.remove(space.id)
                                            }
                                        }
                                    ))
                                    .toggleStyle(.checkbox)
                                    .font(.caption)
                                }
                                
                                if !settings.selectedSpaceIDs.isEmpty {
                                    Button("Clear All") {
                                        settings.selectedSpaceIDs.removeAll()
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                        
                        Text("Leave all unchecked to show tasks from all spaces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            if showingValidation {
                HStack {
                    Image(systemName: validationMessage.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(validationMessage.contains("Success") ? .green : .red)
                    Text(validationMessage)
                        .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(width: 500, height: 600)
    }
    
    private func validateCredentials() {
        isValidating = true
        showingValidation = false
        
        Task {
            let isValid = await ClickUpAPI.shared.validateCredentials()
            
            await MainActor.run {
                isValidating = false
                showingValidation = true
                validationMessage = isValid
                    ? "✓ Success! Credentials are valid."
                    : "✗ Failed to validate. Please check your API key and Team ID."
                
                // Hide validation message after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showingValidation = false
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
