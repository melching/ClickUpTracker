# Developer Guide

Technical documentation for building and modifying ClickUp Time Tracker.

## Project Overview

**Language:** Swift 5.9  
**UI Framework:** SwiftUI  
**Build System:** Swift Package Manager  
**Minimum macOS:** 14.0 (Sonoma)

## Project Structure

```
ClickUpTracker/
├── ClickUpTrackerApp.swift       # App entry point
├── TimeTracker.swift              # Time tracking logic
├── ClickUpAPI.swift               # API client
├── TaskCache.swift                # Local caching system
├── SettingsManager.swift          # Settings persistence
├── NotificationManager.swift      # Notification handling
├── MenuBarView.swift              # Menu bar UI
├── TaskSelectorView.swift         # Task selection dialog
├── SettingsView.swift             # Settings UI
├── Package.swift                  # SPM configuration
├── create-app-bundle.sh           # Bundle creation script
├── run-with-logs.sh               # Debug launcher
├── README.md                      # Main documentation
└── docs/                          # Documentation
    ├── USER_GUIDE.md
    ├── DEVELOPER_GUIDE.md
    ├── API_REFERENCE.md
    ├── TROUBLESHOOTING.md
    └── archive/                   # Old documentation
```

## Architecture

### MVVM Pattern

**Model:**
- `ClickUpTask` - Task data structure
- `ClickUpTimeEntry` - Time entry structure
- Settings stored in UserDefaults

**ViewModel:**
- `TimeTracker` - Tracks elapsed time
- `TaskCache` - Manages task caching
- `SettingsManager` - Manages settings
- `ClickUpAPI` - API communication

**View:**
- `MenuBarView` - Menu bar interface
- `TaskSelectorView` - Task selection dialog
- `SettingsView` - Settings interface

### Data Flow

```
User Action → View → ViewModel → Model → API
     ↑                                      ↓
     └──────────── Response ←───────────────┘
```

### Key Components

**TimeTracker:**
- Singleton pattern
- Timer-based tracking
- Published properties for UI updates

**TaskCache:**
- Singleton pattern
- Disk persistence (JSON)
- Auto-refresh timer
- Client-side search

**ClickUpAPI:**
- Async/await for network calls
- Error handling with custom types
- Pagination support
- Rate limiting consideration

## Building

### Prerequisites

```bash
# Check Swift version
swift --version
# Requires 5.9 or later

# Check macOS version
sw_vers
# Requires 14.0 or later
```

### Build Commands

**Debug Build:**
```bash
swift build
```

**Release Build:**
```bash
swift build -c release
```

**Clean Build:**
```bash
rm -rf .build
swift build -c release
```

**Create App Bundle:**
```bash
./create-app-bundle.sh
```

**Run:**
```bash
# From bundle
open ClickUpTracker.app

# From terminal (with logs)
./ClickUpTracker.app/Contents/MacOS/ClickUpTracker

# Using debug script
./run-with-logs.sh
```

### Build Output

**Binary Location:**
```
.build/release/ClickUpTracker
```

**App Bundle:**
```
ClickUpTracker.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── ClickUpTracker
│   └── Resources/
```

## Development Workflow

### 1. Make Code Changes

Edit Swift files in your preferred editor.

### 2. Build

```bash
swift build
```

### 3. Test

```bash
# Run with logging
./run-with-logs.sh

# Test specific functionality
```

### 4. Create Bundle

```bash
./create-app-bundle.sh
```

### 5. Verify

```bash
open ClickUpTracker.app
```

## Code Style

### Naming Conventions

**Classes/Structs:**
```swift
class TimeTracker { }
struct ClickUpTask { }
```

**Variables:**
```swift
var elapsedTime: TimeInterval
let taskCache: TaskCache
```

**Functions:**
```swift
func startTracking()
func fetchTasks() async throws
```

**Constants:**
```swift
private let baseURL = "https://api.clickup.com/api/v2"
```

### SwiftUI Patterns

**State Management:**
```swift
@State private var searchText = ""
@StateObject private var cache = TaskCache.shared
@ObservedObject var settings = SettingsManager.shared
@Published var isTracking = false
```

**View Structure:**
```swift
var body: some View {
    VStack {
        // Content
    }
    .onAppear {
        // Setup
    }
}
```

**Async Operations:**
```swift
Task {
    do {
        let result = try await someAsyncOperation()
        await MainActor.run {
            // Update UI
        }
    } catch {
        // Handle error
    }
}
```

## Key Features Implementation

### Time Tracking

**Start:**
```swift
func start() {
    startTime = Date()
    isTracking = true
    
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        self.elapsedTime = Date().timeIntervalSince(self.startTime!)
    }
}
```

**Stop:**
```swift
func stop() -> TimeInterval {
    timer?.invalidate()
    timer = nil
    isTracking = false
    return elapsedTime
}
```

### Task Caching

**Save to Disk:**
```swift
func saveToDisk() {
    let encoder = JSONEncoder()
    let data = try? encoder.encode(CacheData(tasks: tasks, lastUpdated: lastUpdated))
    try? data?.write(to: cacheFileURL)
}
```

**Load from Disk:**
```swift
func loadFromDisk() {
    guard let data = try? Data(contentsOf: cacheFileURL),
          let cache = try? JSONDecoder().decode(CacheData.self, from: data) else {
        return
    }
    
    tasks = cache.tasks
    lastUpdated = cache.lastUpdated
}
```

**Search:**
```swift
func search(query: String, assignedOnly: Bool) -> [ClickUpTask] {
    guard query.count >= 2 else { return [] }
    
    var filtered = tasks
    
    // Apply assigned filter
    if assignedOnly, let userID = currentUserID {
        filtered = filtered.filter { task in
            task.assignees?.contains { $0.id == userID } ?? false
        }
    }
    
    // Apply search filter
    filtered = filtered.filter { task in
        task.name.localizedCaseInsensitiveContains(query) ||
        (task.description?.localizedCaseInsensitiveContains(query) ?? false)
    }
    
    return Array(filtered.prefix(50))
}
```

### API Integration

**Fetch Tasks:**
```swift
func fetchAllTasks(progressCallback: ((Int) -> Void)? = nil) async throws -> [ClickUpTask] {
    var allTasks: [ClickUpTask] = []
    var page = 0
    var hasMore = true
    
    while hasMore {
        let tasks = try await fetchTasks(page: page)
        allTasks.append(contentsOf: tasks)
        
        if let callback = progressCallback {
            await MainActor.run {
                callback(allTasks.count)
            }
        }
        
        hasMore = tasks.count >= 100
        page += 1
    }
    
    return allTasks
}
```

**Create Time Entry:**
```swift
func createTimeEntry(taskID: String, duration: TimeInterval, description: String?, billable: Bool) async throws {
    let urlString = "\(baseURL)/team/\(teamID)/time_entries"
    guard let url = URL(string: urlString) else {
        throw ClickUpAPIError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let startMillis = Int64(Date().addingTimeInterval(-duration).timeIntervalSince1970 * 1000)
    let durationMillis = Int64(duration * 1000)
    
    let timeEntry = ClickUpTimeEntry(
        tid: taskID,
        description: description,
        start: startMillis,
        duration: durationMillis,
        billable: billable
    )
    
    request.httpBody = try JSONEncoder().encode(timeEntry)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw ClickUpAPIError.apiError("Request failed")
    }
}
```

### Time Rounding

**Round to Next Minute:**
```swift
var roundedTime: TimeInterval {
    let duration = adjustedTime
    guard duration > 0 else { return duration }
    
    let minutes = duration / 60.0
    let roundedMinutes = ceil(minutes)
    return roundedMinutes * 60.0
}
```

### Time Validation

**Ensure End After Start:**
```swift
DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
    .onChange(of: startTime) { oldValue, newValue in
        if newValue >= endTime {
            endTime = newValue.addingTimeInterval(60) // +1 min
        }
    }

DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
    .onChange(of: endTime) { oldValue, newValue in
        if newValue <= startTime {
            startTime = newValue.addingTimeInterval(-60) // -1 min
        }
    }
```

## Testing

### Manual Testing

**Time Tracking:**
1. Start tracking
2. Wait a few seconds
3. Stop tracking
4. Verify elapsed time

**Task Search:**
1. Open task selector
2. Type search query
3. Verify results appear
4. Test filters

**Time Entry:**
1. Track time
2. Select task
3. Adjust times
4. Toggle billable
5. Submit
6. Verify in ClickUp

### Debug Output

**Console Logging:**
```swift
print("⏱️ Tracking: \(isTracking)")
print("📝 Task: \(task.name)")
print("🌐 API: \(url)")
print("📤 Request: \(jsonString)")
print("📥 Response: \(responseString)")
print("✅ Success")
print("❌ Error: \(error)")
```

**Run with Logs:**
```bash
./run-with-logs.sh
```

### Testing Checklist

- [ ] Time tracking starts/stops correctly
- [ ] Search returns results
- [ ] Task cache refreshes
- [ ] Time entry submits successfully
- [ ] Billable flag works
- [ ] Description appears in ClickUp
- [ ] Duration rounds correctly
- [ ] Time validation prevents invalid entries
- [ ] Settings persist across restarts
- [ ] Notifications appear (if enabled)

## Adding New Features

### 1. Add Data Model

```swift
struct NewFeature: Codable {
    let id: String
    let name: String
}
```

### 2. Add API Method

```swift
func fetchNewFeature() async throws -> NewFeature {
    // API call logic
}
```

### 3. Add ViewModel

```swift
class NewFeatureManager: ObservableObject {
    @Published var data: NewFeature?
    
    func load() async {
        // Load data
    }
}
```

### 4. Add UI

```swift
struct NewFeatureView: View {
    @StateObject var manager = NewFeatureManager()
    
    var body: some View {
        // UI implementation
    }
}
```

### 5. Test

- Build and run
- Verify functionality
- Check logs
- Test edge cases

## Common Tasks

### Change API Endpoint

Edit `ClickUpAPI.swift`:
```swift
private let baseURL = "https://api.clickup.com/api/v2"
```

### Add New Setting

1. **Add to SettingsManager:**
```swift
@Published var newSetting: Bool = false {
    didSet {
        UserDefaults.standard.set(newSetting, forKey: "new_setting")
    }
}
```

2. **Initialize in init():**
```swift
self.newSetting = UserDefaults.standard.bool(forKey: "new_setting")
```

3. **Add to SettingsView:**
```swift
Toggle("New Setting", isOn: $settings.newSetting)
```

### Add New Time Entry Field

1. **Update ClickUpTimeEntry:**
```swift
struct ClickUpTimeEntry: Codable {
    // ... existing fields
    let newField: String?
}
```

2. **Update createTimeEntry:**
```swift
let timeEntry = ClickUpTimeEntry(
    // ... existing fields
    newField: value
)
```

3. **Update TaskSelectorView:**
```swift
@State private var newFieldValue = ""

TextField("New Field", text: $newFieldValue)
```

## Debugging

### Enable Verbose Logging

Add more print statements:
```swift
print("🔍 Debug: Variable = \(variable)")
print("📊 State: \(state)")
```

### Check File Locations

```bash
# Cache file
cat ~/Library/Application\ Support/ClickUpTracker/task-cache.json

# Settings
defaults read com.yourcompany.ClickUpTracker
```

### Network Debugging

Use proxy like Charles or Proxyman to inspect API calls.

### Memory/Performance

Use Instruments to profile:
```bash
xcrun xctrace record --template 'Time Profiler' --launch ClickUpTracker
```

## Deployment

### Create Release Build

```bash
# Clean build
rm -rf .build ClickUpTracker.app

# Build release
swift build -c release

# Create bundle
./create-app-bundle.sh

# Verify
open ClickUpTracker.app
```

### Distribution

**Option 1: Direct Distribution**
- Share `ClickUpTracker.app` directly
- Users can copy to Applications

**Option 2: GitHub Releases**
- Zip the app bundle
- Create GitHub release
- Upload zip file

**Option 3: Homebrew Cask**
- Create cask formula
- Submit to homebrew-cask

### Code Signing (Optional)

For notarization:
```bash
codesign --deep --force --sign "Developer ID Application" ClickUpTracker.app
```

## Contributing

### Pull Request Process

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Update documentation
6. Submit PR

### Code Review Checklist

- [ ] Code follows style guide
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Performance considerations
- [ ] Error handling

## Resources

- [Swift Documentation](https://docs.swift.org/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [ClickUp API Docs](https://clickup.com/api/)
- [Swift Package Manager](https://swift.org/package-manager/)

---

For API details, see [API Reference](API_REFERENCE.md).  
For usage information, see [User Guide](USER_GUIDE.md).
