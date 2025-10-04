//
//  MenuBarView.swift
//  ClickUpTracker
//
//  Main popover view for the menu bar application
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var timeTracker = TimeTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var showingSettings = false
    @State private var showingTaskSelector = false
    @State private var showingDiscardAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("ClickUp Time Tracker")
                .font(.headline)
                .padding(.top, 12)
            
            Divider()
            
            // Current tracked time (readonly)
            VStack(spacing: 4) {
                Text("Current Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(timeTracker.displayTime)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(timeTracker.state == .tracking ? .green : .primary)
            }
            .padding(.vertical, 8)
            
            // Status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Control buttons
            VStack(spacing: 8) {
                // Start/Pause button
                Button(action: {
                    if timeTracker.state == .tracking {
                        timeTracker.pause()
                        updateMenuBarIcon()
                    } else {
                        timeTracker.start()
                        updateMenuBarIcon()
                        NotificationManager.shared.scheduleTrackingReminders()
                    }
                }) {
                    HStack {
                        Image(systemName: timeTracker.state == .tracking ? "pause.circle.fill" : "play.circle.fill")
                        Text(timeTracker.state == .tracking ? "Pause Tracking" : "Start Tracking")
                        Spacer()
                        if let shortcut = settings.startStopShortcut {
                            Text(shortcut.displayString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(timeTracker.state == .idle && !settings.isConfigured)
                
                // Stop and assign task
                Button(action: {
                    showingTaskSelector = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Stop & Search Tasks")
                        Spacer()
                        if let shortcut = settings.stopAndAssignShortcut {
                            Text(shortcut.displayString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(timeTracker.state == .idle)
                .tint(.blue)
                
                // Discard button (new)
                Button(action: {
                    showingDiscardAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard Tracked Time")
                        Spacer()
                        if let shortcut = settings.discardShortcut {
                            Text(shortcut.displayString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(timeTracker.state == .idle)
                .tint(.orange)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Settings and Quit buttons
            VStack(spacing: 8) {
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingTaskSelector) {
            TaskSelectorView(elapsedTime: timeTracker.getCurrentElapsedTime())
        }
        .alert("Discard Tracked Time?", isPresented: $showingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                discardTrackedTime()
            }
        } message: {
            Text("Are you sure you want to discard \(timeTracker.getFormattedCurrentTime()) without assigning it to a task? This action cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTaskSelector)) { _ in
            showingTaskSelector = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDiscardConfirmation)) { _ in
            showingDiscardAlert = true
        }
    }
    
    private var statusColor: Color {
        switch timeTracker.state {
        case .tracking:
            return .green
        case .paused:
            return .orange
        case .idle:
            return .gray
        }
    }
    
    private var statusText: String {
        switch timeTracker.state {
        case .tracking:
            return "Tracking..."
        case .paused:
            return "Paused"
        case .idle:
            return "Not tracking"
        }
    }
    
    private func updateMenuBarIcon() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.updateMenuBarIcon()
        }
    }
    
    private func discardTrackedTime() {
        // Stop tracking and reset without assigning
        timeTracker.reset()
        
        // Cancel notifications
        NotificationManager.shared.cancelTrackingReminders()
        
        // Update menu bar icon
        updateMenuBarIcon()
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
    }
}
