# User Guide

Complete guide to using ClickUp Time Tracker.

## Table of Contents

- [Getting Started](#getting-started)
- [Tracking Time](#tracking-time)
- [Searching Tasks](#searching-tasks)
- [Time Adjustment](#time-adjustment)
- [Billable Tracking](#billable-tracking)
- [Settings](#settings)
- [Tips & Tricks](#tips--tricks)

## Getting Started

### First Time Setup

1. **Get ClickUp Credentials:**
   - API Key: ClickUp Settings → Apps → API Token
   - Team ID: From workspace URL `https://app.clickup.com/{TEAM_ID}/`

2. **Configure App:**
   - Open ClickUpTracker
   - Click menu bar icon → Settings
   - Enter API Key and Team ID
   - Click "Done"

3. **Initial Cache Load:**
   - First search will load all tasks (may take a moment)
   - Tasks are cached locally for fast subsequent searches
   - Auto-refreshes based on your settings

## Tracking Time

### Start Tracking

**Method 1: Menu Bar**
1. Click ⏱️ icon in menu bar
2. Select "Start Tracking"
3. Icon changes to show active tracking

**Method 2: Notification Prompt**
- If you haven't tracked in a while, app will remind you

### While Tracking

- **Menu bar shows:** ⏱️ with elapsed time tooltip
- **Click icon** to see menu with current time
- **Stop anytime** by selecting "Stop & Assign to Task"

### Stop and Assign

1. Click "Stop & Assign to Task"
2. Task selector window opens
3. Search for your task
4. Review/adjust time details
5. Add description (optional)
6. Toggle billable if needed
7. Click "Assign Time"

**What Happens:**
- Time entry created in ClickUp
- Tracking resets to 0
- Notifications cancelled
- Ready to start tracking again

## Searching Tasks

### Basic Search

1. Type 2+ characters in search box
2. Results appear instantly (from cache)
3. Shows up to 50 matching tasks
4. Searches both title and description

### Search Filters

**Assigned to Me:**
- Toggle ☑️ "Assigned to Me"
- Shows only tasks assigned to you
- Useful for focused work sessions

**All Tasks:**
- Uncheck filter
- Shows all tasks you have access to
- Better for collaborative work

### Task Information

Each result shows:
- **Task Name** (bold if selected)
- **Status Badge** (e.g., "In Progress")
- **List/Folder** name
- **🏁 Milestone Badge** (if applicable)
- **↗ Open Button** (opens task in ClickUp)

### Selecting a Task

**Method 1: Click Row**
- Click anywhere on task row
- Task becomes bold/highlighted

**Method 2: Search and Enter**
- Type to narrow results
- Click desired task
- Ready to submit

### Opening Tasks in ClickUp

- Click **↗** button on any task
- Opens task in default browser
- Useful for checking details before tracking

## Time Adjustment

### Editable Time Fields

**Start Time:**
- Shows when tracking started
- Click to open DatePicker
- Adjust date and/or time
- Use calendar or type directly

**End Time:**
- Shows when tracking stopped
- Click to open DatePicker
- Adjust date and/or time
- Must be after start time

**Duration:**
- Auto-calculated from start and end
- Displays in HH:MM:SS format
- Rounded up to next minute when submitted
- Red text if invalid (shouldn't happen with validation)

### Time Validation

**Automatic Adjustments:**
- If you set start >= end, end moves forward by 1 minute
- If you set end <= start, start moves backward by 1 minute
- Always maintains minimum 1 minute duration

**Examples:**

**Forgot to Start Early:**
```
Original:  Start: 2:00 PM, End: 2:30 PM (30 min)
Adjust:    Start: 1:30 PM, End: 2:30 PM (60 min)
Result:    1 hour tracked ✓
```

**Took a Break:**
```
Original:  Start: 2:00 PM, End: 4:00 PM (120 min)
Adjust:    End: 3:30 PM
Result:    90 minutes tracked ✓
```

**Wrong Day:**
```
Original:  Start: Oct 3, 2:00 PM
Adjust:    Start: Oct 2, 2:00 PM
Result:    Tracked for Oct 2 ✓
```

### Duration Rounding

Time is automatically rounded up to the next minute:
- 30 seconds → 1 minute
- 1 minute 1 second → 2 minutes
- 5 minutes → 5 minutes (no change)

This ensures accurate minute-based tracking in ClickUp.

## Billable Tracking

### Setting Default

1. Settings → Time Tracking
2. Toggle "Track time as billable by default"
3. New time entries will start with this setting

**When to Use:**
- If most of your work is billable: Turn ON
- If most of your work is non-billable: Turn OFF

### Per-Entry Override

In task selector:
1. See "Track as billable" toggle
2. Starts with your default setting
3. Toggle ON/OFF as needed for this entry
4. Submit

**Use Cases:**
- Default is billable, but this task isn't: Toggle OFF
- Default is non-billable, but this task is: Toggle ON

### Requirements for Billable

**ClickUp Workspace:**
- Billable time tracking must be enabled
- Check: Workspace Settings → Time Tracking

**User Permissions:**
- Your role must allow billable time tracking
- Contact workspace admin if needed

**API Key:**
- Must have time tracking permissions
- Regenerate if needed

## Settings

### ClickUp Configuration

**API Key** (required)
- Your personal ClickUp API token
- Get from: Settings → Apps → API Token
- Stored securely in macOS Keychain

**Team ID** (required)
- Your workspace team ID
- Find in URL: `https://app.clickup.com/{TEAM_ID}/`
- Usually a numeric value

### Notifications

**Reminder Frequency:**
- **Never** - No tracking reminders
- **Every 15 minutes** - Frequent reminders
- **Every 30 minutes** - Regular reminders
- **Every hour** - Infrequent reminders

**When You'll Be Notified:**
- Only when actively tracking time
- Reminder to stop and assign task
- Or continue tracking if still working

### Task Cache

**Auto-refresh Task Cache:**
- **ON** - Cache updates automatically
- **OFF** - Manual refresh only (click 🔄)

**Refresh Interval:**
- **Every 5 minutes** - Most current data
- **Every 15 minutes** - Balanced
- **Every 30 minutes** - Less frequent
- **Every hour** - Minimal updates

**Cache Status:**
- Shows total tasks cached
- Shows last update time
- Example: "1,247 tasks | Updated 5 minutes ago"

**Clear Cache:**
- Removes all cached tasks
- Next search will reload from ClickUp
- Use if seeing outdated data

### Time Tracking

**Track time as billable by default:**
- **ON** - New entries start billable
- **OFF** - New entries start non-billable
- Can override per entry

## Tips & Tricks

### Fast Workflow

1. **⌘Tab** to ClickUpTracker
2. Click menu bar → "Start Tracking"
3. Work on task
4. Click menu bar → "Stop & Assign"
5. Type task name (2 chars)
6. Click task
7. Click "Assign Time"

### Keyboard Navigation

- **Tab** - Move between fields
- **Arrow Keys** - Navigate task list
- **Enter** - Select highlighted task
- **⌘W** - Close window
- **⌘Q** - Quit app

### Search Tips

**Narrow Results Fast:**
- Use unique words from task name
- Use ticket numbers (e.g., "PROJ-123")
- Use status keywords

**Find Recent Tasks:**
- Recent tasks appear in cache
- Use "Assigned to Me" filter
- Search by your working date

### Time Entry Best Practices

**Add Descriptions:**
- Helps remember what you did
- Useful for reports and billing
- Be specific but concise

**Round Appropriately:**
- App rounds to next minute automatically
- Consider breaks when adjusting times
- Be honest about actual work time

**Use Billable Correctly:**
- Set default to your most common case
- Override for exceptions
- Check with team about billable policies

### Cache Management

**Optimal Settings:**
- Enable auto-refresh
- Use 15-minute interval for active projects
- Use 60-minute interval for stable projects

**When to Clear Cache:**
- After major ClickUp reorganization
- If seeing deleted tasks
- If tasks missing that should be there

**Manual Refresh:**
- Click 🔄 before starting work session
- Ensures you have latest tasks
- Shows "Refreshing..." during update

### Troubleshooting Quick Fixes

**Search too slow:**
- Check cache is loaded (see task count)
- Click 🔄 to refresh if stuck

**Can't find task:**
- Try searching description keywords
- Uncheck "Assigned to Me" filter
- Check task exists in ClickUp

**Time entry failed:**
- Verify internet connection
- Check API key is still valid
- Ensure task still exists

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘,` | Open Settings |
| `⌘W` | Close Window |
| `⌘Q` | Quit App |
| `Tab` | Next Field |
| `↑↓` | Navigate List |
| `Enter` | Select Task |
| `Esc` | Cancel/Close |

## Getting Help

1. Check [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review [API Reference](API_REFERENCE.md) for technical details
3. Check ClickUp API status
4. Create GitHub issue with logs

## Advanced Usage

### Multiple Workspaces

Currently supports one workspace at a time. To switch:
1. Settings → Change Team ID
2. Clear cache
3. Refresh to load new workspace tasks

### API Rate Limits

ClickUp API has rate limits:
- App caches tasks to minimize API calls
- Time entry submission counts toward limit
- Auto-refresh spreads out API usage

### Offline Usage

**What Works:**
- Task search (from cache)
- Time tracking
- Time adjustment

**What Doesn't:**
- Cache refresh
- Time entry submission
- Opening tasks in ClickUp

App will show errors when trying offline operations.

---

For technical details, see [Developer Guide](DEVELOPER_GUIDE.md).
