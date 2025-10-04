# ClickUpTracker

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

A native macOS menu bar application for intelligent time tracking with ClickUp integration. Built with Swift and SwiftUI.

## Overview

ClickUpTracker is a professional time tracking app that lives in your macOS menu bar. It features smart segment-based time tracking, visual status indicators, and seamless ClickUp integration with full control over your time entries before submission.

## 📸 Screenshots

| General | Assign Task | Settings |
|---|---|---|
| ![General](docs/assets/general.png) | ![Assign Task](docs/assets/assign-task.png) | ![Settings](docs/assets/settings.png) |

## ✨ Key Features

### 🎯 Smart Time Tracking

- **Segment-Based Tracking**: Tracks separate time segments without automatic merging
- **Visual Status Indicators**: Menu bar icon changes color based on tracking state
  - 🟢 Green: Actively tracking
  - 🟠 Orange: Paused
  - ⚪ Gray: Idle
- **Pause & Resume**: Multiple start/stop cycles preserved as separate segments
- **Real-time Display**: Live tracking shows seconds; overview displays in clean minutes

### ⏱️ Intelligent Time Processing

- **Configurable Minimum Increments**: Round time to 1, 10, 15, or 30 minutes
- **Smart Segment Merging**: Automatically handles overlapping time periods
- **Preview Before Submit**: See exactly what will be submitted to ClickUp
- **Flexible Editing**: Adjust start/end times for each segment before submission

### 🔍 Powerful Task Management

- **Local Cache**: Fast client-side search with auto-refresh
- **Space Filtering**: Filter tasks by ClickUp spaces (with readable space names)
- **Task Status Display**: Color-coded badges showing current task state
- **Archived Tasks**: Automatically filtered out
- **Subtask Support**: Search includes subtasks

### 💼 Professional Features

- **Billable Tracking**: Toggle billable status per entry (default configurable)
- **Rich Descriptions**: Add context to time entries
- **Full Time Data**: Submits both duration and end time to ClickUp
- **Smart Notifications**: Configurable reminders when tracking is active

## 🚀 Running ClickUpTracker

You must build the app before running it for the first time. The provided `ClickUpTracker.app` is only a template and will not work until you build the project.

You can run ClickUpTracker in several ways, depending on your needs:

### 1. Create a Full .app Bundle (Recommended)

To build a complete, fully functional macOS app bundle:

```sh
./create-app-bundle.sh
```
This script builds the executable, creates a proper `.app` bundle with all required resources, and enables full macOS integration including system notifications and menu bar functionality.

### 2. Build and Run from Source (Development)

For development and testing without creating a bundle:

```sh
./build.sh
```
This script cleans, builds, and optionally launches the raw executable using Swift Package Manager. Note: The raw executable may lack some macOS integrations like notifications.

### 3. Run with Console Logging (Debugging)

To see all log output and debug API issues, use the provided script:

```sh
./run-with-logs.sh
```
This will show all `print()` statements and API call logs in your terminal.

### 4. Standard Run (after building)

- Double-click `ClickUpTracker.app` in Finder, or
- Run from Terminal:
  ```sh
  open ClickUpTracker.app
  ```

---

- All scripts must be run from the project root directory.
- For more details, see the comments in each script file.
