# Quick Start Guide

## Getting Started in 5 Minutes

### 1. Install Python 3.12+ (if not already installed)
```bash
# Check if Python 3.12+ is installed
python3 --version

# If not installed, download from python.org or use Homebrew:
brew install python@3.12
```

### 2. Install uv Package Manager
```bash
# Install uv
pip3 install uv
```

### 3. Clone and Setup
```bash
# Clone the repository
git clone https://github.com/melching/ClickUpTracker.git
cd ClickUpTracker

# Run the setup script
./setup.sh
```

### 4. Get Your ClickUp API Token
1. Go to https://app.clickup.com/
2. Click your avatar (bottom left)
3. Select "Settings"
4. Click "Apps" in the left sidebar
5. Scroll to "API Token"
6. Click "Generate" (or copy existing token)

### 4. Configure the App
**Option A: Edit config.json**
```json
{
    "api_token": "pk_YOUR_TOKEN_HERE",
    "team_id": "YOUR_TEAM_ID"
}
```

**Option B: Use the app settings**
1. Run the app: `python3 clickup_tracker.py`
2. Click the menubar icon (⏱️)
3. Select "⚙️ Settings"
4. Paste your API token
5. Click "Save"

### 5. Start Tracking!
1. Click the menubar icon
2. Click "🎯 Assign Task" (optional)
3. Click "▶️ Start Tracking"
4. Work on your task
5. Click "⏸ Pause/Stop Tracking" when done

## Tips & Tricks

### Running on Startup
To run the app automatically when you log in:

1. Open System Preferences → Users & Groups
2. Click your user, then "Login Items"
3. Create a simple launcher script:

```bash
#!/bin/bash
cd /path/to/ClickUpTracker
python3 clickup_tracker.py
```

4. Save it as `launch_clickup_tracker.sh` and make it executable
5. Add it to Login Items

### Keyboard Shortcuts
The app currently uses mouse clicks, but you can use macOS accessibility features to add keyboard shortcuts to menubar items.

### Task Assignment
- Use task ID for exact match: `abc123`
- Use search terms to find tasks: `fix bug`
- Search is case-insensitive

### Viewing in ClickUp
All tracked time appears in:
- ClickUp → Time Tracking view
- Individual task pages
- Team timesheets

## Troubleshooting

### "ModuleNotFoundError: No module named 'rumps'"
Run: `pip3 install -r requirements.txt`

### "Permission denied" on setup.sh
Run: `chmod +x setup.sh`

### App doesn't appear in menubar
- Check if Python script is running: `ps aux | grep clickup_tracker`
- Try running with sudo: `sudo python3 clickup_tracker.py` (not recommended)
- Check macOS permissions for accessibility

### Timer out of sync
Click "🔄 Refresh" to sync with ClickUp's server

## What Gets Tracked?

The app tracks:
- ✅ Start time
- ✅ End time
- ✅ Duration (automatically calculated)
- ✅ Associated task (if assigned)
- ✅ User (from API token)

The app does NOT track:
- ❌ Descriptions (use ClickUp web interface for detailed notes)
- ❌ Billable status (defaults to non-billable)
- ❌ Tags (use ClickUp web interface)

## Next Steps

- Set up your preferred tasks for quick access
- Explore ClickUp's time tracking reports
- Consider creating a custom workflow with the API client

## Need Help?

- Check the [main README](README.md) for detailed documentation
- Review ClickUp API docs: https://clickup.com/api
- Submit an issue on GitHub
