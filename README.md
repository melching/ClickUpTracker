# ClickUpTracker

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

A native macOS menu bar application for intelligent time tracking with ClickUp integration. Built with Swift and SwiftUI.

## Overview

ClickUpTracker is a professional time tracking app that lives in your macOS menu bar. It features smart segment-based time tracking, visual status indicators, and seamless ClickUp integration with full control over your time entries before submission.

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
