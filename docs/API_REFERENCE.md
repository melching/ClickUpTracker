# API Reference

Technical documentation for ClickUp API integration.

## Overview

ClickUp Time Tracker uses ClickUp API v2 for all operations:
- Fetching tasks with pagination
- Fetching spaces for name enrichment
- Creating time entries with duration and end time
- Team/workspace information

**Base URL:** `https://api.clickup.com/api/v2`

## Authentication

### API Key

All requests require authentication via API token:

```swift
request.setValue(apiKey, forHTTPHeaderField: "Authorization")
```

**Getting Your API Key:**
1. ClickUp → Settings → Apps
2. Click "Generate" under API Token
3. Copy token (starts with `pk_`)

**Permissions Required:**
- View tasks
- View spaces
- Time tracking (read/write)

## Endpoints Used

### 1. Fetch Tasks

**Endpoint:** `GET /team/{team_id}/task`

**Purpose:** Retrieve all tasks accessible to the user

**Query Parameters:**
- `page` (integer) - Page number for pagination (starts at 0)
- `archived` (boolean) - Whether to include archived tasks (set to `false`)
- `subtasks` (boolean) - Whether to include subtasks (set to `true`)
- `include_closed` (boolean) - Whether to include closed tasks (set to `false`)

**Request:**
```http
GET /api/v2/team/123/task?page=0&archived=false&subtasks=true&include_closed=false
Authorization: pk_YOUR_API_KEY
```

**Response:**
```json
{
  "tasks": [
    {
      "id": "86c5t46vm",
      "name": "Task Name",
      "text_content": "Task description",
      "description": "Raw HTML description",
      "status": {
        "status": "in progress",
        "color": "#1090e0"
      },
      "list": {
        "id": "123",
        "name": "List Name"
      },
      "folder": {
        "id": "456",
        "name": "Folder Name"
      },
      "space": {
        "id": "10883364"
      },
      "milestone": null
    }
  ]
}
```

**Note:** Space object in task response only includes `id`, not `name`. Space names must be fetched separately (see endpoint #2).

**Pagination:**
- Returns up to 100 tasks per page
- Fetch all pages until < 100 tasks returned
- App loads all pages and caches locally

**Implementation:**
```swift
func fetchTasks(page: Int = 0) async throws -> [ClickUpTask] {
    var urlComponents = URLComponents(string: "\(baseURL)/team/\(teamID)/task")!
    urlComponents.queryItems = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "archived", value: "false"),
        URLQueryItem(name: "subtasks", value: "true"),
        URLQueryItem(name: "include_closed", value: "false")
    ]
    // ... request logic
}
```

---

### 2. Fetch Spaces

**Endpoint:** `GET /team/{team_id}/space`

**Purpose:** Retrieve all spaces in the team to get space names

**Query Parameters:** None

**Request:**
```http
GET /api/v2/team/123/space
Authorization: pk_YOUR_API_KEY
```

**Response:**
```json
{
  "spaces": [
    {
      "id": "10883364",
      "name": "Marketing"
    },
    {
      "id": "6761559",
      "name": "Development"
    }
  ]
}
```

**Implementation:**
```swift
func fetchSpaces() async throws -> [ClickUpSpace] {
    let urlString = "\(baseURL)/team/\(teamID)/space"
    // ... request logic
    let spacesResponse = try JSONDecoder().decode(ClickUpSpacesResponse.self, from: data)
    return spacesResponse.spaces
}
```

**Usage:**
Space names are fetched during cache refresh and enriched into task data:

```swift
// Fetch spaces first
let spaces = try await ClickUpAPI.shared.fetchSpaces()
let spaceNameMap = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0.name) })

// Fetch tasks
let tasks = try await ClickUpAPI.shared.fetchAllTasks()

// Enrich tasks with space names
let enrichedTasks = tasks.map { task in
    var enrichedTask = task
    if let spaceID = task.space?.id, let spaceName = spaceNameMap[spaceID] {
        enrichedTask.space = ClickUpTask.Space(id: spaceID, name: spaceName)
    }
    return enrichedTask
}
```

---

### 3. Create Time Entry

**Endpoint:** `POST /team/{team_id}/time_entries`

**Purpose:** Create a new time tracking entry

**Request Body:**
```json
{
  "tid": "86c5t46vm",
  "start": 1696339200000,
  "end": 1696339380000,
  "duration": 180000,
  "description": "Work description",
  "billable": true
}
```

**Field Specifications:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tid` | string | ✅ | Task ID |
| `start` | int64 | ✅ | Start time - Unix timestamp in milliseconds |
| `end` | int64 | ❌ | End time - Unix timestamp in milliseconds |
| `duration` | int64 | ✅ | Duration in milliseconds |
| `description` | string | ❌ | Work description (omitted if empty) |
| `billable` | boolean | ✅ | Whether time is billable |

**Important:** Both `end` and `duration` are now submitted to provide complete time entry data to ClickUp.

**Request:**
```http
POST /api/v2/team/123/time_entries
Authorization: pk_YOUR_API_KEY
Content-Type: application/json

{
  "tid": "86c5t46vm",
  "start": 1696339200000,
  "end": 1696339380000,
  "duration": 180000,
  "description": "Implemented feature",
  "billable": true
}
```

**Response:**
```json
{
  "data": {
    "id": "4760080178167497735",
    "task": {
      "id": "86c5t46vm",
      "name": "Task Name",
      "status": {
        "status": "in progress",
        "id": "c90153765002_abc123",
        "color": "#1090e0",
        "type": "custom",
        "orderindex": 1
      }
    },
    "wid": "4505195",
    "user": {
      "id": 12345,
      "username": "user@example.com",
      "email": "user@example.com",
      "color": "#04a9f4",
      "initials": "UE",
      "timezone": "America/New_York"
    },
    "billable": true,
    "start": 1696339200000,
    "end": "1696339380000",
    "duration": 180000,
    "description": "Implemented feature",
    "at": 1696339400000,
    "is_locked": false
  }
}
```

**Implementation:**
```swift
func createTimeEntry(
    taskID: String,
    startTime: Date,
    duration: TimeInterval,
    description: String?,
    billable: Bool = false
) async throws {
    let endTime = startTime.addingTimeInterval(duration)
    
    let startMillis = Int64(startTime.timeIntervalSince1970 * 1000)
    let endMillis = Int64(endTime.timeIntervalSince1970 * 1000)
    let durationMillis = Int64(duration * 1000)
    
    let timeEntry = ClickUpTimeEntry(
        tid: taskID,
        description: description,
        start: startMillis,
        end: endMillis,      // Now included
        duration: durationMillis,
        billable: billable
    )
    
    let urlString = "\(baseURL)/team/\(teamID)/time_entries"
    // ... request logic
}
```

## Data Models

---

## Data Models

### ClickUpTask

```swift
struct ClickUpTask: Codable, Identifiable {
    let id: String
    let name: String
    let status: Status?
    let list: List?
    let folder: Folder?
    var space: Space?  // Mutable to allow enrichment with space name
    let milestone: Milestone?
    let textContent: String?  // Task description for searching
    let description: String?  // Raw description
    
    var isMilestone: Bool {
        milestone != nil
    }
    
    struct Status: Codable {
        let status: String
        let color: String?
    }
    
    struct List: Codable {
        let id: String
        let name: String
    }
    
    struct Folder: Codable {
        let id: String
        let name: String
    }
    
    struct Space: Codable {
        let id: String
        var name: String?  // May be nil initially, enriched from fetchSpaces()
        
        init(id: String, name: String? = nil) {
            self.id = id
            self.name = name
        }
    }
    
    struct Milestone: Codable {
        let id: String?
    }
}
```

### ClickUpSpace

```swift
struct ClickUpSpace: Codable {
    let id: String
    let name: String
}

struct ClickUpSpacesResponse: Codable {
    let spaces: [ClickUpSpace]
}
```

### ClickUpTimeEntry

```swift
struct ClickUpTimeEntry: Codable {
    let tid: String           // Task ID
    let description: String?  // Optional description
    let start: Int64          // Start time in milliseconds
    let end: Int64?           // End time in milliseconds (optional)
    let duration: Int64       // Duration in milliseconds
    let billable: Bool        // Billable flag
    
    enum CodingKeys: String, CodingKey {
        case tid
        case description
        case start
        case end
        case duration
        case billable
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(tid, forKey: .tid)
        
        // Only encode description if not nil
        if let description = description {
            try container.encode(description, forKey: .description)
        }
        
        try container.encode(start, forKey: .start)
        
        // Encode end time if available
        if let end = end {
            try container.encode(end, forKey: .end)
        }
        
        try container.encode(duration, forKey: .duration)
        try container.encode(billable, forKey: .billable)
    }
}
```

### TaskStatus

```swift
struct TaskStatus: Codable {
    let status: String
    let color: String?
}
```

### TaskList

```swift
struct TaskList: Codable {
    let id: String
    let name: String
}
```

### TaskFolder

```swift
struct TaskFolder: Codable {
    let id: String
    let name: String
}
```

### Assignee

```swift
struct Assignee: Codable {
    let id: Int
    let username: String
}
```

### Milestone

```swift
struct Milestone: Codable {
    // Milestone-specific fields
}
```

### ClickUpTimeEntry

```swift
struct ClickUpTimeEntry: Codable {
    let tid: String           // Task ID
    let description: String?  // Optional description
    let start: Int64          // Unix timestamp (ms)
    let duration: Int64       // Duration (ms)
    let billable: Bool        // Billable flag
}
```

---

## Error Handling

### Error Types

```swift
enum ClickUpAPIError: Error {
    case invalidURL
    case invalidAPIKey
    case invalidTeamID
    case networkError(Error)
    case apiError(String)
}
```

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Request completed |
| 401 | Unauthorized | Invalid API key |
| 403 | Forbidden | No permission |
| 404 | Not Found | Task/team doesn't exist |
| 429 | Rate Limited | Wait and retry |
| 500 | Server Error | ClickUp issue, retry later |

### Error Examples

**401 Unauthorized:**
```json
{
  "err": "Token invalid",
  "ECODE": "OAUTH_013"
}
```

**404 Not Found:**
```json
{
  "err": "Team not found",
  "ECODE": "TEAM_NOT_FOUND"
}
```

**429 Rate Limited:**
```json
{
  "err": "Rate limit exceeded"
}
```

---

## Rate Limits

### ClickUp API Limits

- **100 requests per minute** per API key
- **Rate limit headers** returned in responses
- **Retry-After** header when limited

### App Mitigation Strategies

1. **Local Caching:**
   - Caches all tasks locally
   - Reduces API calls for search
   - Only fetches when refreshing

2. **Paginated Loading:**
   - Loads tasks in pages of 100
   - Spreads requests over time
   - Shows progress to user

3. **Auto-Refresh Intervals:**
   - Configurable: 5, 15, 30, 60 minutes
   - Avoids constant API polling
   - User can disable if needed

4. **Single Time Entry:**
   - Only calls API when submitting
   - No unnecessary retries
   - Clear error messages

---

## Implementation Details

### API Client

```swift
class ClickUpAPI: ObservableObject {
    static let shared = ClickUpAPI()
    
    private let baseURL = "https://api.clickup.com/api/v2"
    
    @Published var apiKey: String = ""
    @Published var teamID: String = ""
    
    // Fetch tasks with pagination
    func fetchTasks(page: Int = 0) async throws -> [ClickUpTask]
    
    // Load all tasks (all pages)
    func fetchAllTasks(progressCallback: ((Int) -> Void)?) async throws -> [ClickUpTask]
    
    // Create time entry
    func createTimeEntry(taskID: String, duration: TimeInterval, description: String?, billable: Bool) async throws
    
    // Validate credentials
    func validateCredentials() async -> Bool
}
```

### Task Caching

```swift
class TaskCache: ObservableObject {
    static let shared = TaskCache()
    
    @Published var tasks: [ClickUpTask] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    
    // Save to disk
    func saveToDisk()
    
    // Load from disk
    func loadFromDisk()
    
    // Refresh from API
    func refresh() async
    
    // Search cached tasks
    func search(query: String, assignedOnly: Bool) -> [ClickUpTask]
}
```

### Time Tracking

```swift
class TimeTracker: ObservableObject {
    static let shared = TimeTracker()
    
    @Published var isTracking = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var startTime: Date?
    
    private var timer: Timer?
    
    func start()
    func stop() -> TimeInterval
    func reset()
}
```

---

## API Migration Notes

### Old API (Deprecated)

```
POST /api/v2/task/{task_id}/time

Body: {
  "start": 1696339200000,
  "time": 180000,
  "description": "...",
  "billable": true
}
```

**Issues:**
- Field name was `time` (should be `duration`)
- Task ID in URL path
- Billable flag not respected
- Description field not working

### New API (Current)

```
POST /api/v2/team/{team_id}/time_entries

Body: {
  "tid": "task_id",
  "start": 1696339200000,
  "duration": 180000,
  "description": "...",
  "billable": true
}
```

**Improvements:**
- Correct field name: `duration`
- Task ID in body: `tid`
- Billable flag works correctly
- Description field works correctly
- Team-based endpoint

---

## Code Examples

### Fetch All Tasks

```swift
func loadAllTasks() async {
    do {
        let tasks = try await ClickUpAPI.shared.fetchAllTasks { count in
            print("Loaded \(count) tasks so far...")
        }
        
        TaskCache.shared.tasks = tasks
        TaskCache.shared.saveToDisk()
        
        print("✅ Loaded \(tasks.count) tasks total")
    } catch {
        print("❌ Error loading tasks: \(error)")
    }
}
```

### Create Time Entry

```swift
func submitTime(to task: ClickUpTask, duration: TimeInterval) async {
    do {
        try await ClickUpAPI.shared.createTimeEntry(
            taskID: task.id,
            duration: duration,
            description: "Implemented feature X",
            billable: true
        )
        
        print("✅ Time entry created")
    } catch {
        print("❌ Failed to create time entry: \(error)")
    }
}
```

### Search Tasks

```swift
func searchTasks(query: String) -> [ClickUpTask] {
    guard query.count >= 2 else { return [] }
    
    return TaskCache.shared.tasks.filter { task in
        let nameMatch = task.name.localizedCaseInsensitiveContains(query)
        let descMatch = task.description?.localizedCaseInsensitiveContains(query) ?? false
        return nameMatch || descMatch
    }.prefix(50).map { $0 }
}
```

---

## Testing API Manually

### Test Authentication

```bash
curl -H "Authorization: YOUR_API_KEY" \
  https://api.clickup.com/api/v2/team
```

### Test Fetch Tasks

```bash
curl -H "Authorization: YOUR_API_KEY" \
  "https://api.clickup.com/api/v2/team/TEAM_ID/task?page=0"
```

### Test Create Time Entry

```bash
curl -X POST \
  -H "Authorization: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tid": "TASK_ID",
    "start": 1696339200000,
    "duration": 180000,
    "description": "Test",
    "billable": true
  }' \
  https://api.clickup.com/api/v2/team/TEAM_ID/time_entries
```

---

## References

- **ClickUp API Docs:** https://clickup.com/api/
- **Time Entries:** https://clickup.com/api/clickupreference/operation/CreateTimeEntry/
- **Tasks:** https://clickup.com/api/clickupreference/operation/GetTasks/

---

For usage information, see [User Guide](USER_GUIDE.md).
