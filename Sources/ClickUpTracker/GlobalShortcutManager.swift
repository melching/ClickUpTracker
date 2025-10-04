//
//  GlobalShortcutManager.swift
//  ClickUpTracker
//
//  Manages global keyboard shortcuts using Carbon Event Manager
//

import Foundation
import AppKit
import Carbon.HIToolbox
import UserNotifications

class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()
    
    private var hotKeyRefs: [String: EventHotKeyRef] = [:]
    private var hotKeyHandlers: [UInt32: () -> Void] = [:]
    private var nextHotKeyID: UInt32 = 1
    private var eventHandler: EventHandlerRef?
    
    private init() {
        setupEventHandler()
    }
    
    deinit {
        unregisterAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
    
    // Setup the Carbon event handler
    private func setupEventHandler() {
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]
        
        let callback: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let error = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if error == noErr {
                manager.hotKeyHandlers[hotKeyID.id]?()
            }
            
            return noErr
        }
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            eventTypes.count,
            &eventTypes,
            selfPtr,
            &eventHandler
        )
    }
    
    // Register a global shortcut with a unique name
    func register(name: String, shortcut: KeyboardShortcut, handler: @escaping () -> Void) -> Bool {
        // Unregister existing shortcut with same name if any
        unregister(name: name)
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B545243), id: nextHotKeyID) // 'KTRC'
        nextHotKeyID += 1
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard status == noErr, let ref = hotKeyRef else {
            print("Failed to register hotkey '\(name)': status \(status)")
            return false
        }
        
        hotKeyRefs[name] = ref
        hotKeyHandlers[hotKeyID.id] = handler
        
        print("Registered global shortcut '\(name)': \(shortcut.displayString)")
        return true
    }
    
    // Unregister a specific shortcut by name
    func unregister(name: String) {
        guard let hotKeyRef = hotKeyRefs[name] else { return }
        
        UnregisterEventHotKey(hotKeyRef)
        hotKeyRefs.removeValue(forKey: name)
        
        print("Unregistered global shortcut '\(name)'")
    }
    
    // Unregister all shortcuts
    func unregisterAll() {
        for (name, hotKeyRef) in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
            print("Unregistered global shortcut '\(name)'")
        }
        hotKeyRefs.removeAll()
        hotKeyHandlers.removeAll()
    }
    
    // Update shortcuts from SettingsManager
    func updateFromSettings() {
        let settings = SettingsManager.shared
        
        // Update start/pause shortcut
        if let shortcut = settings.startStopShortcut {
            _ = register(name: "startStop", shortcut: shortcut) {
                self.handleStartStop()
            }
        } else {
            unregister(name: "startStop")
        }
        
        // Update stop and assign shortcut
        if let shortcut = settings.stopAndAssignShortcut {
            _ = register(name: "stopAndAssign", shortcut: shortcut) {
                self.handleStopAndAssign()
            }
        } else {
            unregister(name: "stopAndAssign")
        }
        
        // Update discard shortcut
        if let shortcut = settings.discardShortcut {
            _ = register(name: "discard", shortcut: shortcut) {
                self.handleDiscard()
            }
        } else {
            unregister(name: "discard")
        }
    }
    
    // Action handlers
    private func handleStartStop() {
        DispatchQueue.main.async {
            let tracker = TimeTracker.shared
            if tracker.state == .tracking {
                tracker.pause()
            } else {
                tracker.start()
                NotificationManager.shared.scheduleTrackingReminders()
            }
            
            // Update menu bar icon
            if let appDelegate = AppDelegate.shared {
                appDelegate.updateMenuBarIcon()
            }
        }
    }
    
    private func handleStopAndAssign() {
        DispatchQueue.main.async {
            let tracker = TimeTracker.shared
            
            // Only proceed if we have time tracked
            guard tracker.state != .idle else {
                return
            }
            
            // Show the task selector window directly
            if let appDelegate = AppDelegate.shared {
                appDelegate.showTaskSelectorWindow()
            }
        }
    }
    
    private func handleDiscard() {
        DispatchQueue.main.async {
            let tracker = TimeTracker.shared
            
            // Only proceed if we have time tracked
            guard tracker.state != .idle else {
                return
            }
            
            // Show the discard confirmation dialog directly
            if let appDelegate = AppDelegate.shared {
                appDelegate.showDiscardConfirmationWindow()
            }
        }
    }
}

// Notification names for cross-component communication
extension Notification.Name {
    static let showTaskSelector = Notification.Name("showTaskSelector")
    static let showDiscardConfirmation = Notification.Name("showDiscardConfirmation")
}
