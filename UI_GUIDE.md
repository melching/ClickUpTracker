# User Interface Guide

## Menubar App Visual Guide

### App States

#### 1. Not Tracking (Default State)
```
┌─────────────────────────────────┐
│  ⏱️  ClickUp Tracker            │
├─────────────────────────────────┤
│  Status: Not Tracking           │
│  ─────────────────────────────  │
│  ▶️ Start Tracking              │
│  ─────────────────────────────  │
│  🎯 Assign Task                 │
│  ─────────────────────────────  │
│  ⚙️  Settings                   │
│  🔄 Refresh                     │
│  ❌ Quit                        │
└─────────────────────────────────┘
```

#### 2. Tracking Active
```
┌─────────────────────────────────┐
│  ⏱️ ▶️  ClickUp Tracker         │
├─────────────────────────────────┤
│  Tracking: Fix login bug        │
│  Duration: 00:15:43             │
│  ─────────────────────────────  │
│  ⏸  Pause/Stop Tracking         │
│  ─────────────────────────────  │
│  🎯 Assign Task                 │
│  ─────────────────────────────  │
│  ⚙️  Settings                   │
│  🔄 Refresh                     │
│  ❌ Quit                        │
└─────────────────────────────────┘
```

#### 3. Configuration Warning
```
┌─────────────────────────────────┐
│  ⏱️ ⚠️  ClickUp Tracker         │
├─────────────────────────────────┤
│  Status: Not Configured         │
│  ─────────────────────────────  │
│  ▶️ Start Tracking              │
│  ─────────────────────────────  │
│  🎯 Assign Task                 │
│  ─────────────────────────────  │
│  ⚙️  Settings  ← Configure!     │
│  🔄 Refresh                     │
│  ❌ Quit                        │
└─────────────────────────────────┘
```

## Dialog Windows

### Settings Dialog
```
╔════════════════════════════════════╗
║          Settings                  ║
╠════════════════════════════════════╣
║                                    ║
║  Enter your ClickUp API Token:     ║
║  (Get it from ClickUp Settings     ║
║   → Apps)                          ║
║                                    ║
║  ┌──────────────────────────────┐ ║
║  │ pk_xxxxxxxxxxxxxxxxxxxxx     │ ║
║  └──────────────────────────────┘ ║
║                                    ║
║     [ Cancel ]      [ Save ]       ║
║                                    ║
╚════════════════════════════════════╝
```

### Assign Task Dialog (Search)
```
╔════════════════════════════════════╗
║        Assign Task                 ║
╠════════════════════════════════════╣
║                                    ║
║  Enter ClickUp Task ID or          ║
║  search term:                      ║
║                                    ║
║  ┌──────────────────────────────┐ ║
║  │ fix bug                      │ ║
║  └──────────────────────────────┘ ║
║                                    ║
║     [ Cancel ]    [ Search ]       ║
║                                    ║
╚════════════════════════════════════╝
```

### Task Selection Dialog
```
╔════════════════════════════════════╗
║        Select Task                 ║
╠════════════════════════════════════╣
║                                    ║
║  Found 3 tasks. Enter task ID:     ║
║                                    ║
║  ┌──────────────────────────────┐ ║
║  │ abc123                       │ ║
║  └──────────────────────────────┘ ║
║                                    ║
║     [ Cancel ]    [ Select ]       ║
║                                    ║
╚════════════════════════════════════╝
```

### Quit Confirmation
```
╔════════════════════════════════════╗
║        Confirm Quit                ║
╠════════════════════════════════════╣
║                                    ║
║  You have an active timer.         ║
║  Are you sure you want to quit?    ║
║                                    ║
║   [ Cancel ]   [ Quit Anyway ]     ║
║                                    ║
╚════════════════════════════════════╝
```

## Notifications

### Tracking Stopped
```
┌──────────────────────────────────┐
│  ClickUp Tracker                 │
├──────────────────────────────────┤
│  Tracking Stopped                │
│                                  │
│  Time entry has been saved       │
│  to ClickUp                      │
└──────────────────────────────────┘
```

### Task Assigned
```
┌──────────────────────────────────┐
│  ClickUp Tracker                 │
├──────────────────────────────────┤
│  Task Assigned                   │
│                                  │
│  Now tracking: Fix login bug     │
└──────────────────────────────────┘
```

### Error Notification
```
┌──────────────────────────────────┐
│  ClickUp Tracker                 │
├──────────────────────────────────┤
│  Error                           │
│                                  │
│  Failed to connect to ClickUp    │
└──────────────────────────────────┘
```

## User Flows

### Flow 1: First Time Setup
```
1. Launch app
   │
   ├─→ See ⏱️ ⚠️ in menubar (warning icon)
   │
2. Click menubar icon
   │
   ├─→ See "Status: Not Configured"
   │
3. Click "⚙️ Settings"
   │
   ├─→ Settings dialog appears
   │
4. Enter API token → Click "Save"
   │
   ├─→ "Success" alert
   ├─→ Icon changes to ⏱️ (no warning)
   │
5. Ready to track!
```

### Flow 2: Start Tracking with Task
```
1. Click menubar icon ⏱️
   │
2. Click "🎯 Assign Task"
   │
   ├─→ Enter search term: "fix bug"
   │
3. Click "Search"
   │
   ├─→ Results shown, enter task ID
   │
4. Click "Select"
   │
   ├─→ Notification: "Task Assigned"
   │
5. Click "▶️ Start Tracking"
   │
   ├─→ Timer starts
   ├─→ Icon changes to ⏱️ ▶️
   ├─→ Menu shows task name & duration
   │
6. Work on task...
   │
7. Click "⏸ Pause/Stop Tracking"
   │
   ├─→ Timer stops
   ├─→ Notification: "Tracking Stopped"
   ├─→ Time saved to ClickUp
   │
8. Done!
```

### Flow 3: Quick Start (No Task)
```
1. Click menubar icon ⏱️
   │
2. Click "▶️ Start Tracking"
   │
   ├─→ Timer starts immediately
   ├─→ Shows "No Task Assigned"
   │
3. Work...
   │
4. Click "⏸ Pause/Stop Tracking"
   │
   ├─→ Time saved to ClickUp
```

### Flow 4: Resume After Restart
```
1. App was tracking before quit
   │
2. Relaunch app
   │
   ├─→ Automatically detects running timer
   ├─→ Shows task name
   ├─→ Shows elapsed time
   ├─→ Icon shows ⏱️ ▶️
   │
3. Continue working or stop as normal
```

## Keyboard Navigation

While the app primarily uses mouse clicks, you can use macOS accessibility features:

```
System Preferences → Keyboard → Shortcuts
→ Add custom shortcuts for menu items
```

## Tips for Best Experience

### Tip 1: Pin to Menubar
- App stays in menubar until you quit
- Survives system sleep/wake
- Minimal memory footprint

### Tip 2: Task ID Shortcuts
- Save frequently used task IDs
- Use ClickUp browser extension to copy IDs
- Task IDs are in URL: clickup.com/t/TASKID

### Tip 3: Timer Accuracy
- Timer updates every second
- Synced with ClickUp server on start/stop
- Safe to close/reopen app

### Tip 4: Multiple Workspaces
- App uses first workspace by default
- To change: edit team_id in config.json
- Find team IDs in ClickUp settings

## Troubleshooting Visual Cues

```
⏱️       = Ready to track
⏱️ ▶️    = Currently tracking
⏱️ ⚠️    = Configuration needed
```

## Menu Item Meanings

```
Status: Not Tracking     = Timer is off
Tracking: [Task Name]    = Timer is running for this task
Duration: HH:MM:SS       = Current elapsed time

▶️ Start Tracking        = Begin timing
⏸ Pause/Stop Tracking   = End timing session
🎯 Assign Task           = Select which task to track
⚙️ Settings              = Configure API token
🔄 Refresh               = Check for server updates
❌ Quit                  = Exit application
```

## Color Scheme

The app uses emoji for visual indicators:
- ⏱️ Timer icon (neutral)
- ▶️ Play icon (active/green concept)
- ⏸ Pause icon (warning/yellow concept)
- 🎯 Target icon (focus)
- ⚙️ Settings icon (configuration)
- 🔄 Refresh icon (sync)
- ❌ Quit icon (stop/red concept)
- ⚠️ Warning icon (needs attention)

## Screen Examples

When app is tracking, you'll see something like:

```
Menubar: [other apps] | ⏱️ ▶️ | [clock] [wifi]

Dropdown Menu:
┌─────────────────────────────────┐
│  Tracking: Implement new feature│
│  Duration: 01:23:45             │
│  ─────────────────────────────  │
│  ⏸  Pause/Stop Tracking         │
└─────────────────────────────────┘
```

This provides at-a-glance information without opening ClickUp!
