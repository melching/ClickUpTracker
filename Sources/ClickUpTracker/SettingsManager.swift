//
//  SettingsManager.swift
//  ClickUpTracker
//
//  Manages application settings with UserDefaults persistence
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "clickup_api_key")
        }
    }
    
    @Published var teamID: String {
        didSet {
            UserDefaults.standard.set(teamID, forKey: "clickup_team_id")
        }
    }
    
    @Published var notificationFrequency: NotificationFrequency {
        didSet {
            UserDefaults.standard.set(notificationFrequency.rawValue, forKey: "notification_frequency")
        }
    }
    
    @Published var autoRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "auto_refresh_enabled")
            TaskCache.shared.updateAutoRefreshSettings()
        }
    }
    
    @Published var refreshIntervalMinutes: RefreshInterval {
        didSet {
            UserDefaults.standard.set(refreshIntervalMinutes.rawValue, forKey: "refresh_interval_minutes")
            TaskCache.shared.updateAutoRefreshSettings()
        }
    }
    
    @Published var billableByDefault: Bool {
        didSet {
            UserDefaults.standard.set(billableByDefault, forKey: "billable_by_default")
        }
    }
    
    @Published var minimumTimeIncrement: MinimumTimeIncrement {
        didSet {
            UserDefaults.standard.set(minimumTimeIncrement.rawValue, forKey: "minimum_time_increment")
        }
    }
    
    @Published var selectedSpaceIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedSpaceIDs), forKey: "selected_space_ids")
        }
    }
    
    @Published var startStopShortcut: KeyboardShortcut? {
        didSet {
            if let shortcut = startStopShortcut {
                UserDefaults.standard.set(shortcut.toDictionary(), forKey: "start_stop_shortcut")
            } else {
                UserDefaults.standard.removeObject(forKey: "start_stop_shortcut")
            }
            // Defer the update to avoid recursive initialization
            DispatchQueue.main.async {
                GlobalShortcutManager.shared.updateFromSettings()
            }
        }
    }
    
    @Published var stopAndAssignShortcut: KeyboardShortcut? {
        didSet {
            if let shortcut = stopAndAssignShortcut {
                UserDefaults.standard.set(shortcut.toDictionary(), forKey: "stop_and_assign_shortcut")
            } else {
                UserDefaults.standard.removeObject(forKey: "stop_and_assign_shortcut")
            }
            // Defer the update to avoid recursive initialization
            DispatchQueue.main.async {
                GlobalShortcutManager.shared.updateFromSettings()
            }
        }
    }
    
    @Published var discardShortcut: KeyboardShortcut? {
        didSet {
            if let shortcut = discardShortcut {
                UserDefaults.standard.set(shortcut.toDictionary(), forKey: "discard_shortcut")
            } else {
                UserDefaults.standard.removeObject(forKey: "discard_shortcut")
            }
            // Defer the update to avoid recursive initialization
            DispatchQueue.main.async {
                GlobalShortcutManager.shared.updateFromSettings()
            }
        }
    }
    
    var refreshInterval: TimeInterval {
        return TimeInterval(refreshIntervalMinutes.rawValue * 60)
    }
    
    var isConfigured: Bool {
        !apiKey.isEmpty && !teamID.isEmpty
    }
    
    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "clickup_api_key") ?? ""
        self.teamID = UserDefaults.standard.string(forKey: "clickup_team_id") ?? ""
        
        let frequencyValue = UserDefaults.standard.integer(forKey: "notification_frequency")
        self.notificationFrequency = NotificationFrequency(rawValue: frequencyValue) ?? .everyHour
        
        self.autoRefreshEnabled = UserDefaults.standard.bool(forKey: "auto_refresh_enabled")
        
        let intervalValue = UserDefaults.standard.integer(forKey: "refresh_interval_minutes")
        self.refreshIntervalMinutes = RefreshInterval(rawValue: intervalValue) ?? .every15Minutes
        
        self.billableByDefault = UserDefaults.standard.bool(forKey: "billable_by_default")
        
        let incrementValue = UserDefaults.standard.integer(forKey: "minimum_time_increment")
        self.minimumTimeIncrement = MinimumTimeIncrement(rawValue: incrementValue) ?? .oneMinute
        
        let spaceIDsArray = UserDefaults.standard.stringArray(forKey: "selected_space_ids") ?? []
        self.selectedSpaceIDs = Set(spaceIDsArray)
        
        // Load shortcuts
        if let shortcutDict = UserDefaults.standard.dictionary(forKey: "start_stop_shortcut") {
            self.startStopShortcut = KeyboardShortcut(from: shortcutDict)
        } else {
            self.startStopShortcut = nil
        }
        
        if let shortcutDict = UserDefaults.standard.dictionary(forKey: "stop_and_assign_shortcut") {
            self.stopAndAssignShortcut = KeyboardShortcut(from: shortcutDict)
        } else {
            self.stopAndAssignShortcut = nil
        }
        
        if let shortcutDict = UserDefaults.standard.dictionary(forKey: "discard_shortcut") {
            self.discardShortcut = KeyboardShortcut(from: shortcutDict)
        } else {
            self.discardShortcut = nil
        }
    }
}

enum NotificationFrequency: Int, CaseIterable, Identifiable {
    case every30Minutes = 30
    case everyHour = 60
    case every2Hours = 120
    case every3Hours = 180
    case disabled = 0
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .every30Minutes:
            return "Every 30 minutes"
        case .everyHour:
            return "Every hour"
        case .every2Hours:
            return "Every 2 hours"
        case .every3Hours:
            return "Every 3 hours"
        case .disabled:
            return "Disabled"
        }
    }
    
    var intervalInSeconds: TimeInterval {
        return TimeInterval(rawValue * 60)
    }
}

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case every5Minutes = 5
    case every15Minutes = 15
    case every30Minutes = 30
    case everyHour = 60
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .every5Minutes:
            return "Every 5 minutes"
        case .every15Minutes:
            return "Every 15 minutes"
        case .every30Minutes:
            return "Every 30 minutes"
        case .everyHour:
            return "Every hour"
        }
    }
}

enum MinimumTimeIncrement: Int, CaseIterable, Identifiable {
    case oneMinute = 1
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .oneMinute:
            return "1 minute"
        case .tenMinutes:
            return "10 minutes"
        case .fifteenMinutes:
            return "15 minutes"
        case .thirtyMinutes:
            return "30 minutes"
        }
    }
    
    var seconds: TimeInterval {
        return TimeInterval(rawValue * 60)
    }
}
