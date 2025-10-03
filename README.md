# ClickUpTracker

A simple macOS menubar app that provides an easy interface for time tracking with ClickUp. Mostly coded using LLMs as a hobby project.

## Features

- 🚀 **Simple Interface**: One-click start/pause and stop tracking
- 🎯 **Task Assignment**: Easily assign tasks to your time entries
- ⏱️ **Live Timer**: See elapsed time directly in the menubar
- 🔄 **Auto-sync**: Automatically syncs with existing ClickUp timers
- 📊 **Menubar Access**: Quick access from your macOS menubar

## Requirements

- macOS (10.10 or later)
- Python 3.12 or higher
- ClickUp account with API access
- uv (Python package manager)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/melching/ClickUpTracker.git
   cd ClickUpTracker
   ```

2. **Install uv (if not already installed):**
   ```bash
   pip install uv
   ```

3. **Install dependencies using uv:**
   ```bash
   uv pip install -r requirements.txt
   # Or using pyproject.toml:
   uv pip install -e .
   ```

4. **Get your ClickUp API token:**
   - Go to ClickUp Settings → Apps
   - Click "Generate" under API Token
   - Copy your token

5. **Configure the app:**
   - Copy `config.example.json` to `config.json`
   - Or run the app and use the Settings menu to enter your API token

## Usage

### Running the App

```bash
python3 clickup_tracker.py
```

The app will appear in your macOS menubar.

### Basic Operations

1. **First Time Setup:**
   - Click the menubar icon
   - Select "⚙️ Settings"
   - Enter your ClickUp API token
   - Click "Save"

2. **Start Tracking:**
   - Click the menubar icon
   - Click "▶️ Start Tracking"
   - Timer starts immediately

3. **Assign a Task:**
   - Click "🎯 Assign Task"
   - Enter a task ID or search term
   - Select from search results

4. **Stop Tracking:**
   - Click "⏸ Pause/Stop Tracking"
   - Time entry is automatically saved to ClickUp

### Features

- **Live Timer**: The menubar shows elapsed time while tracking
- **Auto-Resume**: If you quit with a running timer, it will resume on restart
- **Task Search**: Search for tasks by name or use task ID directly
- **Status Display**: Shows current tracking status and task name

## Project Structure

```
ClickUpTracker/
├── clickup_tracker.py      # Main menubar application
├── clickup_client.py        # ClickUp API client
├── requirements.txt         # Python dependencies
├── config.example.json      # Example configuration file
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Configuration

The app uses a `config.json` file to store your settings:

```json
{
    "api_token": "YOUR_CLICKUP_API_TOKEN",
    "team_id": "YOUR_TEAM_ID"
}
```

The `team_id` is automatically detected when you save your API token in Settings.

## Troubleshooting

### "Configuration Error" on startup
- Check that your API token is valid
- Ensure you have internet connectivity
- Verify your ClickUp account is accessible

### "No tasks found"
- Make sure you have access to tasks in your workspace
- Try searching with different keywords
- Use the exact task ID if known

### Timer not showing
- Click "🔄 Refresh" to sync with ClickUp
- Restart the application
- Check ClickUp web interface for active timers

## Development

This project is built with:
- **rumps**: For macOS menubar interface
- **requests**: For ClickUp API communication
- **Python standard library**: For core functionality

## API Reference

The app uses the ClickUp API v2. Key endpoints:
- `/user` - Get user information
- `/team` - List teams/workspaces
- `/team/{team_id}/time_entries/start` - Start time tracking
- `/team/{team_id}/time_entries/stop` - Stop time tracking
- `/team/{team_id}/time_entries/current` - Get running timer
- `/task/{task_id}` - Get task details
- `/team/{team_id}/task` - Search tasks

## License

This is a hobby project built primarily using LLMs. Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## Acknowledgments

Built with assistance from AI coding tools as a learning and productivity project. 
