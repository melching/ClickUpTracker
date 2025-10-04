//
//  KeyboardShortcut.swift
//  ClickUpTracker
//
//  Model for keyboard shortcuts with serialization support
//

import Foundation
import Carbon.HIToolbox

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    init?(keyCode: UInt32, modifiers: UInt32) {
        guard keyCode > 0 else { return nil }
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
    
    // Display string for the shortcut
    var displayString: String {
        var parts: [String] = []
        
        // Add modifier symbols in standard order
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        
        // Add key name
        if let keyName = keyCodeToString(keyCode) {
            parts.append(keyName)
        }
        
        return parts.joined()
    }
    
    // Convert key code to readable string
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        let keyMap: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
            0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
            0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]", 0x1F: "O", 0x20: "U",
            0x21: "[", 0x22: "I", 0x23: "P", 0x24: "↩", 0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K",
            0x29: ";", 0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x30: "⇥",
            0x31: "Space", 0x32: "`", 0x33: "⌫", 0x35: "⎋", 0x39: "Caps Lock",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
            0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
            0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑"
        ]
        
        return keyMap[keyCode]
    }
}

// Extension to convert to/from UserDefaults
extension KeyboardShortcut {
    init?(from dictionary: [String: Any]) {
        guard let keyCode = dictionary["keyCode"] as? UInt32,
              let modifiers = dictionary["modifiers"] as? UInt32 else {
            return nil
        }
        self.init(keyCode: keyCode, modifiers: modifiers)
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "keyCode": keyCode,
            "modifiers": modifiers
        ]
    }
}
