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
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var iconUpdateTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        
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
}
