//
//  TimeTracker.swift
//  ClickUpTracker
//
//  Manages time tracking state and calculations
//

import Foundation
import Combine

enum TrackingState {
    case idle
    case tracking
    case paused
}

struct TimeSegment {
    let startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }
}

class TimeTracker: ObservableObject {
    @Published var state: TrackingState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var displayTime: String = "00:00:00"
    
    // Track each recording segment separately
    private(set) var timeSegments: [TimeSegment] = []
    private(set) var currentSegmentStart: Date?
    private var timer: Timer?
    
    // Singleton instance
    static let shared = TimeTracker()
    
    private init() {}
    
    func start() {
        switch state {
        case .idle:
            // Starting fresh - clear old segments
            timeSegments = []
            currentSegmentStart = Date()
            state = .tracking
            startTimer()
            
        case .paused:
            // Resuming - start a new segment (don't merge with paused time)
            currentSegmentStart = Date()
            state = .tracking
            startTimer()
            
        case .tracking:
            // Already tracking, do nothing
            break
        }
    }
    
    func pause() {
        guard state == .tracking else { return }
        
        // Complete the current segment
        if let start = currentSegmentStart {
            let segment = TimeSegment(startTime: start, endTime: Date())
            timeSegments.append(segment)
            currentSegmentStart = nil
        }
        
        state = .paused
        stopTimer()
    }
    
    func stop() {
        // Complete the current segment if tracking
        if state == .tracking, let start = currentSegmentStart {
            let segment = TimeSegment(startTime: start, endTime: Date())
            timeSegments.append(segment)
            currentSegmentStart = nil
        }
        
        stopTimer()
        state = .idle
    }
    
    func reset() {
        stop()
        timeSegments = []
        currentSegmentStart = nil
        elapsedTime = 0
        displayTime = "00:00:00"
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard state == .tracking, let start = currentSegmentStart else { return }
        
        // Calculate total time: completed segments + current segment
        let completedTime = timeSegments.reduce(0.0) { $0 + $1.duration }
        let currentTime = Date().timeIntervalSince(start)
        elapsedTime = completedTime + currentTime
        displayTime = formatTimeInterval(elapsedTime)
    }
    
    func getCurrentElapsedTime() -> TimeInterval {
        switch state {
        case .tracking:
            // Total of completed segments + current segment
            let completedTime = timeSegments.reduce(0.0) { $0 + $1.duration }
            if let start = currentSegmentStart {
                return completedTime + Date().timeIntervalSince(start)
            }
            return completedTime
        case .paused, .idle:
            // Total of completed segments only
            return timeSegments.reduce(0.0) { $0 + $1.duration }
        }
    }
    
    func getTotalDuration() -> TimeInterval {
        // Helper method to get total duration across all segments
        return timeSegments.reduce(0.0) { $0 + $1.duration }
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formatTimeIntervalWithoutSeconds(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    func getFormattedCurrentTime() -> String {
        return formatTimeInterval(getCurrentElapsedTime())
    }
}
