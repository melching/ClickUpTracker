//
//  ClickUpTrackerApp.swift
//  ClickUpTracker
//
//  A menu bar application for time tracking with ClickUp integration
//

import SwiftUI

@main
struct ClickUpTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var iconUpdateTimer: Timer?
    private var taskSelectorWindow: NSWindow?
    private var discardConfirmationWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "ClickUp Tracker")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        
        // Initialize global shortcuts
        GlobalShortcutManager.shared.updateFromSettings()
        
        // Start timer to update menu bar icon when tracking
        iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        iconUpdateTimer?.invalidate()
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate the app so the popover gets focus
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func showPopover() {
        print("showPopover() called - isShown: \(popover.isShown)")
        
        if let button = statusItem.button {
            if !popover.isShown {
                print("Showing popover directly")
                
                // CRITICAL: Activate app and make it frontmost
                NSApp.activate(ignoringOtherApps: true)
                
                // Small delay to ensure app is active
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    guard let self = self else { return }
                    
                    // Now show the popover
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    
                    // Force the popover window to the front
                    if let popoverWindow = self.popover.contentViewController?.view.window {
                        popoverWindow.level = .floating
                        popoverWindow.makeKeyAndOrderFront(nil)
                        popoverWindow.orderFrontRegardless()
                    }
                    
                    print("Popover.isShown after show: \(self.popover.isShown)")
                }
            } else {
                print("Popover already shown")
            }
        } else {
            print("ERROR: statusItem.button is nil")
        }
    }
    
    func updateMenuBarIcon() {
        let tracker = TimeTracker.shared
        
        if let button = statusItem.button {
            // Create colored icon based on tracking state
            let iconName: String
            let tintColor: NSColor
            
            switch tracker.state {
            case .tracking:
                iconName = "clock.fill"
                tintColor = NSColor.systemGreen
            case .paused:
                iconName = "clock.badge.exclamationmark.fill"
                tintColor = NSColor.systemOrange
            case .idle:
                iconName = "clock"
                tintColor = NSColor.systemGray
            }
            
            // Create the image with color
            if let symbolImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                let coloredImage = symbolImage.copy() as! NSImage
                coloredImage.lockFocus()
                tintColor.set()
                
                let imageRect = NSRect(origin: .zero, size: coloredImage.size)
                imageRect.fill(using: .sourceAtop)
                
                coloredImage.unlockFocus()
                coloredImage.isTemplate = false
                
                button.image = coloredImage
            }
            
            // Update title with current time if tracking or paused
            if tracker.state == .tracking || tracker.state == .paused {
                button.title = " \(tracker.getFormattedCurrentTime())"
            } else {
                button.title = ""
            }
        }
    }
    
    func showTaskSelectorWindow() {
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
        
        // Close existing window if any
        taskSelectorWindow?.close()
        
        let elapsedTime = TimeTracker.shared.getCurrentElapsedTime()
        
        // Create a new window with the task selector
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Stop & Search Tasks"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        let contentView = NSHostingView(rootView: TaskSelectorView(elapsedTime: elapsedTime))
        window.contentView = contentView
        
        window.makeKeyAndOrderFront(nil)
        
        taskSelectorWindow = window
    }
    
    func showDiscardConfirmationWindow() {
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
        
        // Close existing window if any
        discardConfirmationWindow?.close()
        
        // Create confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Discard Tracked Time?"
        alert.informativeText = "Are you sure you want to discard \(TimeTracker.shared.getFormattedCurrentTime()) without assigning it to a task? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // User clicked Discard
            TimeTracker.shared.reset()
            NotificationManager.shared.cancelTrackingReminders()
            updateMenuBarIcon()
        }
    }
}

