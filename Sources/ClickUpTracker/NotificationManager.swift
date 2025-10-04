//
//  NotificationManager.swift
//  ClickUpTracker
//
//  Manages user notifications for time tracking reminders
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private var notificationCenter: UNUserNotificationCenter?
    private var reminderTimer: Timer?
    private var isAvailable = false
    
    override init() {
        super.init()
        
        // Check if we're running in a proper app bundle
        if Bundle.main.bundleIdentifier != nil {
            notificationCenter = UNUserNotificationCenter.current()
            notificationCenter?.delegate = self
            isAvailable = true
            requestAuthorization()
        } else {
            print("⚠️ Notifications unavailable: Running without app bundle")
            print("   To enable notifications, build as .app bundle with Xcode")
            isAvailable = false
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard isAvailable, let center = notificationCenter else { return }
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✓ Notification authorization granted")
            } else if let error = error {
                print("⚠️ Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Schedule Tracking Reminders
    
    func scheduleTrackingReminders() {
        // Cancel any existing reminders
        cancelTrackingReminders()
        
        guard isAvailable else {
            print("⚠️ Skipping notifications (not available)")
            return
        }
        
        let settings = SettingsManager.shared
        
        // Don't schedule if disabled
        guard settings.notificationFrequency != .disabled else { return }
        
        let interval = settings.notificationFrequency.intervalInSeconds
        
        // Schedule repeating timer
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendTrackingReminder()
        }
    }
    
    func cancelTrackingReminders() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        
        // Remove pending notifications
        notificationCenter?.removePendingNotificationRequests(withIdentifiers: ["tracking_reminder"])
    }
    
    private func sendTrackingReminder() {
        guard isAvailable, let center = notificationCenter else { return }
        
        let timeTracker = TimeTracker.shared
        
        // Only send if still tracking
        guard timeTracker.state == .tracking else {
            cancelTrackingReminders()
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time Tracking Active"
        content.body = "You've been tracking time for \(timeTracker.getFormattedCurrentTime()). Don't forget to stop when done!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "tracking_reminder_\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        center.add(request) { error in
            if let error = error {
                print("⚠️ Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap if needed
        completionHandler()
    }
}
