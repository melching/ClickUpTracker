# Recent Changes - v2.0.0

Summary of major enhancements and changes in version 2.0.0

**Date:** October 4, 2025

## Overview

Version 2.0.0 represents a major overhaul of the time tracking system with intelligent segment-based tracking, visual status indicators, and enhanced ClickUp integration.

## 🎯 Major Features

### 1. Segment-Based Time Tracking

**Previous Behavior:**
- Single continuous time tracking
- Stop/start would reset the timer
- No history of pause/resume cycles

**New Behavior:**
- **Multiple Time Segments**: Each start/stop cycle creates a separate time segment
- **No Auto-Merge During Tracking**: Segments are preserved separately while tracking
- **Smart Processing**: Segments are intelligently processed only during submission
- **Editable Segments**: Users can adjust start/end times for each segment

**Implementation:**
```swift
// TimeTracker.swift
struct TimeSegment: Identifiable, Codable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

@Published var timeSegments: [TimeSegment] = []
```

### 2. Visual Status Indicators

**Menu Bar Icon Colors:**
- 🟢 **Green**: Actively tracking time
- 🟠 **Orange**: Tracking paused
- ⚪ **Gray**: Idle (not tracking)

**Implementation:**
- Real-time icon updates every second
- Uses SF Symbols with NSImage color tinting
- Smooth visual feedback for user awareness

**Code:**
```swift
// ClickUpTrackerApp.swift
private func updateMenuBarIcon() {
    let symbolName: String
    let color: NSColor
    
    switch TimeTracker.shared.state {
    case .tracking:
        symbolName = "clock.fill"
        color = .systemGreen
    case .paused:
        symbolName = "clock.fill"
        color = .systemOrange
    case .idle:
        symbolName = "clock"
        color = .systemGray
    }
    
    // Create colored icon...
}
```

### 3. Intelligent Time Processing

**Configurable Minimum Increments:**
- 1 minute (precise tracking)
- 10 minutes (standard)
- 15 minutes (common billing increment)
- 30 minutes (consulting/legal standard)

**Smart Segment Merging:**
- Rounds each segment up to minimum increment
- Merges overlapping or adjacent segments automatically
- Shows preview before submission

**Process Flow:**
```
Raw Segments:
  09:00 - 09:07  (7 min)
  09:15 - 09:28  (13 min)
  
With 10-min minimum:
  09:00 - 09:10  (10 min) ← rounded up
  09:15 - 09:30  (15 min) ← rounded up to next 10-min
  
Result: 2 time entries totaling 25 minutes
```

**Implementation:**
```swift
// TaskSelectorView.swift
func processSegmentsForSubmission() -> [ProcessedSegment] {
    let minimumSeconds = SettingsManager.shared.minimumTimeIncrement.seconds
    
    var processed: [ProcessedSegment] = []
    
    for segment in segments {
        var duration = segment.duration
        
        // Round up to minimum increment
        if duration < minimumSeconds {
            duration = minimumSeconds
        } else {
            let remainder = duration.truncatingRemainder(dividingBy: minimumSeconds)
            if remainder > 0 {
                duration += (minimumSeconds - remainder)
            }
        }
        
        let end = segment.start.addingTimeInterval(duration)
        processed.append(ProcessedSegment(start: segment.start, end: end, duration: duration))
    }
    
    // Merge overlapping segments
    return mergeOverlappingSegments(processed)
}
```

### 4. Date/Time UI Separation

**Previous:**
- Each segment had separate date/time pickers
- Confusing when multiple segments on same day

**New:**
- **Single Date Picker**: One date for all segments
- **Time-Only Pickers**: Start/end times for each segment
- **Cleaner UI**: More compact and logical

**Benefits:**
- Easier to edit multiple segments on the same day
- Less visual clutter
- More intuitive workflow

### 5. Space Filtering with Names

**Previous:**
- Space IDs shown in UI ("Space 10883364")
- No way to know which space was which

**New:**
- **Space Names Displayed**: "Marketing", "Development", etc.
- **Separate API Call**: Fetches spaces with names
- **Data Enrichment**: Space names added to cached tasks

**Implementation:**
```swift
// ClickUpAPI.swift
func fetchSpaces() async throws -> [ClickUpSpace] {
    let urlString = "\(baseURL)/team/\(teamID)/space"
    // ... API call
}

// TaskCache.swift
func refresh() async {
    // Fetch spaces first
    let spaces = try await ClickUpAPI.shared.fetchSpaces()
    let spaceNameMap = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0.name) })
    
    // Fetch tasks
    let tasks = try await ClickUpAPI.shared.fetchAllTasks()
    
    // Enrich with space names
    let enrichedTasks = tasks.map { task in
        var enrichedTask = task
        if let spaceID = task.space?.id, let spaceName = spaceNameMap[spaceID] {
            enrichedTask.space = ClickUpTask.Space(id: spaceID, name: spaceName)
        }
        return enrichedTask
    }
}
```

**Note:** Space filtering is **client-side only**. All tasks are fetched from API, then filtered locally for fast search.

### 6. Full Time Entry Data

**Previous:**
- Only duration submitted to ClickUp
- Missing end time information

**New:**
- **Both Duration and End Time**: Complete time entry data
- **Calculated End Time**: start + duration
- **ClickUp Compatibility**: Follows ClickUp API v2 spec

**Implementation:**
```swift
func createTimeEntry(taskID: String, startTime: Date, duration: TimeInterval, ...) async throws {
    let endTime = startTime.addingTimeInterval(duration)
    
    let startMillis = Int64(startTime.timeIntervalSince1970 * 1000)
    let endMillis = Int64(endTime.timeIntervalSince1970 * 1000)
    let durationMillis = Int64(duration * 1000)
    
    let timeEntry = ClickUpTimeEntry(
        tid: taskID,
        description: description,
        start: startMillis,
        end: endMillis,      // Now included!
        duration: durationMillis,
        billable: billable
    )
}
```

### 7. Task Status Display

**Features:**
- **Color-Coded Badges**: Uses ClickUp's original status colors
- **Status Text**: Shows current state (e.g., "In Progress", "Ready for Stage")
- **Visual Feedback**: Easy to identify task state at a glance

### 8. Time Display Improvements

**Live Tracking:**
- Shows seconds (HH:MM:SS format)
- Real-time updates every second
- Precise feedback during active tracking

**Overview/History:**
- Shows minutes only (e.g., "25 minutes")
- Cleaner, less distracting
- Focus on meaningful durations

### 9. Enhanced Settings

**New Settings:**
- **Minimum Time Increment**: Choose rounding behavior
- **Space Filtering**: Multi-select space filter with names
- **Auto-Refresh Cache**: Toggle and configure interval
- **Billable by Default**: Set default billable status

**Settings Persistence:**
- All settings saved to UserDefaults
- Survive app restarts
- Per-user configuration

## 🔧 Technical Improvements

### API Integration

**Endpoints Added:**
- `GET /team/{team_id}/space` - Fetch spaces with names

**Query Parameters Added:**
- `archived: false` - Exclude archived tasks
- `subtasks: true` - Include subtasks in search
- `include_closed: false` - Focus on active tasks

**Request Body Changes:**
- Time entries now include `end` field
- Optional description handling improved

### Data Models

**Modified:**
- `ClickUpTask.space` - Made mutable for enrichment
- `ClickUpTask.Space` - Added initializer for name enrichment
- `ClickUpTimeEntry` - Added optional `end` field

**Added:**
- `ClickUpSpace` - Space data model
- `ClickUpSpacesResponse` - API response wrapper
- `TimeSegment` - Time segment tracking

### Performance

- **Client-Side Filtering**: Fast search without API calls
- **Local Cache**: Cached tasks with enriched space names
- **Pagination**: Efficient task fetching
- **Async/Await**: Modern concurrency for smooth UI

### Code Quality

- **Type Safety**: Strong typing throughout
- **Error Handling**: Comprehensive error types
- **Documentation**: Inline comments and doc comments
- **Separation of Concerns**: Clear component boundaries

## 📝 Breaking Changes

None - all changes are additive and backward compatible with existing ClickUp data.

## 🐛 Bug Fixes

- Fixed segment merging edge cases
- Improved date/time picker reliability
- Fixed space filtering cache invalidation
- Corrected time entry submission validation

## 📚 Documentation Updates

**Updated Files:**
- `README.md` - Complete rewrite with all new features
- `docs/API_REFERENCE.md` - Added space endpoint, updated time entry fields
- `docs/RECENT_CHANGES.md` - This file (new)

**New Sections:**
- Usage guide for segment-based tracking
- Space filtering documentation
- Visual indicator reference
- Time processing explanation

##  Migration Guide

**For Existing Users:**

1. **Clear Cache**: After updating, clear the task cache in Settings to fetch space names
2. **Review Settings**: Check new minimum time increment setting (defaults to 1 minute)
3. **Space Filter**: Configure space filtering if you only work in specific spaces
4. **Test Workflow**: Try the new segment-based tracking with a test task

**No Data Loss:**
- Existing settings are preserved
- Cached tasks will be refreshed with space names
- Time entries in ClickUp are unaffected

## 🎉 Conclusion

Version 2.0.0 represents a significant evolution of ClickUpTracker, transforming it from a simple timer into an intelligent time tracking assistant. The segment-based approach, combined with smart processing and visual feedback, makes time tracking more accurate and less intrusive while maintaining full control and flexibility.

All changes prioritize user experience, data integrity, and seamless ClickUp integration.
