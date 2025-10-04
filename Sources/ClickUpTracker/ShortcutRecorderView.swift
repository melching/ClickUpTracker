//
//  ShortcutRecorderView.swift
//  ClickUpTracker
//
//  SwiftUI view for recording keyboard shortcuts
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut?
    @State private var isRecording = false
    
    var body: some View {
        HStack(spacing: 8) {
            ShortcutRecorderButton(
                shortcut: shortcut,
                isRecording: $isRecording,
                onShortcutRecorded: { newShortcut in
                    shortcut = newShortcut
                    isRecording = false
                }
            )
            
            if shortcut != nil {
                Button(action: {
                    shortcut = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
    }
}

// NSView-based button that properly captures keyboard events
struct ShortcutRecorderButton: NSViewRepresentable {
    let shortcut: KeyboardShortcut?
    @Binding var isRecording: Bool
    let onShortcutRecorded: (KeyboardShortcut) -> Void
    
    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.shortcut = shortcut
        nsView.isRecording = isRecording
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isRecording: $isRecording, onShortcutRecorded: onShortcutRecorded)
    }
    
    class Coordinator {
        @Binding var isRecording: Bool
        let onShortcutRecorded: (KeyboardShortcut) -> Void
        
        init(isRecording: Binding<Bool>, onShortcutRecorded: @escaping (KeyboardShortcut) -> Void) {
            self._isRecording = isRecording
            self.onShortcutRecorded = onShortcutRecorded
        }
        
        func didRecordShortcut(_ shortcut: KeyboardShortcut) {
            onShortcutRecorded(shortcut)
        }
        
        func didStartRecording() {
            isRecording = true
        }
        
        func didStopRecording() {
            isRecording = false
        }
    }
}

class ShortcutRecorderNSView: NSView {
    var shortcut: KeyboardShortcut?
    var isRecording = false {
        didSet {
            needsDisplay = true
        }
    }
    weak var delegate: ShortcutRecorderButton.Coordinator?
    private var localEventMonitor: Any?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        
        // Add click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleClick() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        delegate?.didStartRecording()
        
        // Start monitoring keyboard events locally
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            
            if event.type == .keyDown {
                self.handleKeyDown(event)
                return nil // Consume the event
            }
            
            return event
        }
        
        // Make this view first responder
        window?.makeFirstResponder(self)
    }
    
    private func stopRecording() {
        isRecording = false
        delegate?.didStopRecording()
        
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Convert NSEvent.ModifierFlags to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        
        if modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        
        // Require at least one modifier
        guard carbonModifiers != 0 else {
            return
        }
        
        // Get the key code
        let keyCode = UInt32(event.keyCode)
        
        // Create and save the shortcut
        if let newShortcut = KeyboardShortcut(keyCode: keyCode, modifiers: carbonModifiers) {
            delegate?.didRecordShortcut(newShortcut)
            stopRecording()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        stopRecording()
        needsDisplay = true
        return true
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 120, height: 24)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw background
        let backgroundColor: NSColor = isRecording 
            ? NSColor.controlAccentColor.withAlphaComponent(0.1)
            : NSColor.secondaryLabelColor.withAlphaComponent(0.1)
        backgroundColor.setFill()
        
        let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        backgroundPath.fill()
        
        // Draw border when recording
        if isRecording {
            NSColor.controlAccentColor.setStroke()
            backgroundPath.lineWidth = 2
            backgroundPath.stroke()
        }
        
        // Draw text
        let text: String
        let textColor: NSColor
        
        if isRecording {
            text = "Press keys..."
            textColor = .secondaryLabelColor
        } else if let shortcut = shortcut {
            text = shortcut.displayString
            textColor = .labelColor
        } else {
            text = "Not set"
            textColor = .secondaryLabelColor
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: textColor
        ]
        
        let textSize = (text as NSString).size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
