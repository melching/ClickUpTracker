# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    macOS Menubar                        │
│                   (System Tray)                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ User Interaction
                     │
┌────────────────────▼────────────────────────────────────┐
│              clickup_tracker.py                         │
│            (ClickUpTrackerApp)                          │
│  ┌──────────────────────────────────────────────┐     │
│  │  - Start/Stop Tracking                        │     │
│  │  - Task Assignment                            │     │
│  │  - Timer Display                              │     │
│  │  - Settings Management                        │     │
│  └──────────────────────────────────────────────┘     │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ API Calls
                     │
┌────────────────────▼────────────────────────────────────┐
│              clickup_client.py                          │
│              (ClickUpClient)                            │
│  ┌──────────────────────────────────────────────┐     │
│  │  - HTTP Request Handling                      │     │
│  │  - Authentication                             │     │
│  │  - Data Serialization                         │     │
│  └──────────────────────────────────────────────┘     │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ HTTPS
                     │
┌────────────────────▼────────────────────────────────────┐
│              ClickUp API v2                             │
│           (api.clickup.com)                             │
│  ┌──────────────────────────────────────────────┐     │
│  │  - Time Entry Management                      │     │
│  │  - Task Management                            │     │
│  │  - User/Team Management                       │     │
│  └──────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## Component Details

### 1. ClickUpTrackerApp (clickup_tracker.py)

**Responsibilities:**
- Manage macOS menubar interface using `rumps`
- Handle user interactions (clicks, menu selections)
- Maintain application state (current task, timer)
- Display real-time tracking information
- Manage configuration (load/save)

**Key Features:**
- Start/pause/stop tracking with one click
- Live timer display in menu
- Task search and assignment
- Settings configuration
- Auto-resume on app restart

**State Management:**
```
- current_task: Currently assigned task (or None)
- tracking_start_time: When tracking started (or None)
- timer: Timer object for UI updates
- client: ClickUpClient instance
- team_id: User's team/workspace ID
```

### 2. ClickUpClient (clickup_client.py)

**Responsibilities:**
- Communicate with ClickUp REST API
- Handle authentication (API token)
- Serialize/deserialize API responses
- Error handling for network requests

**Key Methods:**
- `start_time_entry()`: Start a new time entry
- `stop_time_entry()`: Stop current time entry
- `get_running_time_entry()`: Check for active timer
- `get_task()`: Fetch task details
- `search_tasks()`: Search for tasks
- `get_user()`: Get user information
- `get_teams()`: List workspaces

**API Integration:**
```
Base URL: https://api.clickup.com/api/v2
Authentication: Bearer token in headers
Content-Type: application/json
```

## Data Flow

### Starting a Time Entry

```
User Click "Start"
    │
    ▼
ClickUpTrackerApp.start_tracking()
    │
    ├─► Update UI (show timer)
    │
    ▼
ClickUpClient.start_time_entry(team_id, task_id)
    │
    ├─► POST /team/{team_id}/time_entries/start
    │
    ▼
ClickUp API creates entry
    │
    ▼
Response with entry data
    │
    ▼
App displays "Tracking: [Task Name]"
```

### Stopping a Time Entry

```
User Click "Stop"
    │
    ▼
ClickUpTrackerApp.stop_tracking()
    │
    ├─► Calculate duration
    │
    ▼
ClickUpClient.stop_time_entry(team_id)
    │
    ├─► POST /team/{team_id}/time_entries/stop
    │
    ▼
ClickUp API stops entry and saves
    │
    ▼
Response with final entry data
    │
    ▼
App resets UI and shows notification
```

### Task Assignment

```
User Click "Assign Task"
    │
    ▼
User enters search term
    │
    ▼
ClickUpClient.search_tasks(team_id, query)
    │
    ├─► GET /team/{team_id}/task?search={query}
    │
    ▼
ClickUp API returns matching tasks
    │
    ▼
App displays search results
    │
    ▼
User selects task
    │
    ▼
App stores task for next tracking session
```

## Configuration

### config.json Structure
```json
{
    "api_token": "pk_xxxxx",  // ClickUp API token
    "team_id": "12345"        // Auto-detected team ID
}
```

### Environment Setup
```
requirements.txt:
  - rumps: macOS menubar interface
  - requests: HTTP client for API calls
  - python-dotenv: Environment variable support (future)
```

## Security Considerations

1. **API Token Storage**: Tokens stored in local config.json (gitignored)
2. **HTTPS Only**: All API calls use HTTPS
3. **No Password Storage**: Uses ClickUp's token-based auth
4. **Local Configuration**: No remote config or telemetry

## Future Enhancements

Possible improvements:
- [ ] Keyboard shortcuts for common actions
- [ ] Description/notes field for time entries
- [ ] Multiple workspace support
- [ ] Recent tasks quick-access
- [ ] Weekly/daily time summaries
- [ ] Pomodoro timer integration
- [ ] Notification reminders
- [ ] Time entry editing
- [ ] Offline mode with sync

## Testing Strategy

Current test coverage:
- Unit tests for ClickUpClient methods
- Mock API responses for testing without network
- Configuration file validation
- Project structure validation

Manual testing required:
- macOS menubar integration (requires macOS)
- User interaction flows
- ClickUp API integration (requires account)
- Timer accuracy over long periods

## Dependencies

### Runtime Dependencies
- **Python 3.7+**: Core language
- **rumps**: macOS menubar app framework
- **requests**: HTTP library
- **json**: Built-in JSON handling
- **datetime**: Built-in time/date handling

### Development Dependencies
- **unittest**: Built-in testing framework
- **mock**: Built-in mocking for tests

### System Requirements
- **macOS 10.10+**: Required for menubar app
- **Internet connection**: Required for API access
- **ClickUp account**: Required for time tracking
