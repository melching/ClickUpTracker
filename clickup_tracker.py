"""
ClickUp Time Tracker - macOS Menubar App
"""

import rumps
import json
import os
from datetime import datetime, timedelta
from typing import Optional, Dict
from clickup_client import ClickUpClient


class ClickUpTrackerApp(rumps.App):
    """macOS menubar app for ClickUp time tracking."""
    
    def __init__(self):
        super(ClickUpTrackerApp, self).__init__(
            "ClickUp Tracker",
            icon=None,
            quit_button=None
        )
        # Set title with emoji since icon path causes issues
        self.title = "⏱️"
        
        # Load configuration
        self.config = self.load_config()
        self.client = None
        self.team_id = None
        self.current_task = None
        self.tracking_start_time = None
        self.timer = None
        
        # Initialize client if config is available
        if self.config.get("api_token"):
            try:
                self.client = ClickUpClient(self.config["api_token"])
                self.team_id = self.config.get("team_id")
                # Verify connection
                user = self.client.get_user()
                self.title = "⏱️"
            except Exception as e:
                self.title = "⏱️ ⚠️"
                rumps.alert("Configuration Error", f"Failed to connect to ClickUp: {str(e)}")
        else:
            self.title = "⏱️ ⚠️"
        
        # Build menu
        self.build_menu()
        
        # Check for running timer on startup
        if self.client and self.team_id:
            self.check_existing_timer()
    
    def load_config(self) -> Dict:
        """Load configuration from config.json."""
        config_path = os.path.join(os.path.dirname(__file__), "config.json")
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                return json.load(f)
        return {}
    
    def save_config(self):
        """Save configuration to config.json."""
        config_path = os.path.join(os.path.dirname(__file__), "config.json")
        with open(config_path, "w") as f:
            json.dump(self.config, f, indent=4)
    
    def build_menu(self):
        """Build the application menu."""
        self.menu.clear()
        
        # Status section
        if self.current_task:
            task_name = self.current_task.get("name", "Unknown Task")
            self.menu.add(rumps.MenuItem(f"Tracking: {task_name}", callback=None))
            if self.tracking_start_time:
                elapsed = self.get_elapsed_time()
                self.menu.add(rumps.MenuItem(f"Duration: {elapsed}", callback=None))
            self.menu.add(rumps.separator)
            self.menu.add(rumps.MenuItem("⏸ Pause/Stop Tracking", callback=self.stop_tracking))
        else:
            self.menu.add(rumps.MenuItem("Status: Not Tracking", callback=None))
            self.menu.add(rumps.separator)
            self.menu.add(rumps.MenuItem("▶️ Start Tracking", callback=self.start_tracking))
        
        self.menu.add(rumps.separator)
        
        # Task selection
        self.menu.add(rumps.MenuItem("🎯 Assign Task", callback=self.assign_task))
        
        self.menu.add(rumps.separator)
        
        # Settings and quit
        self.menu.add(rumps.MenuItem("⚙️ Settings", callback=self.show_settings))
        self.menu.add(rumps.MenuItem("🔄 Refresh", callback=self.refresh_menu))
        self.menu.add(rumps.MenuItem("❌ Quit", callback=self.quit_app))
    
    def check_existing_timer(self):
        """Check if there's already a running timer."""
        try:
            running_entry = self.client.get_running_time_entry(self.team_id)
            if running_entry:
                # Get task info if available
                task_id = running_entry.get("task", {}).get("id")
                if task_id:
                    try:
                        task = self.client.get_task(task_id)
                        self.current_task = task
                    except:
                        self.current_task = {"name": "Unknown Task", "id": task_id}
                else:
                    self.current_task = {"name": "No Task Assigned"}
                
                # Set start time from the entry
                start_timestamp = int(running_entry.get("start", 0)) / 1000
                self.tracking_start_time = datetime.fromtimestamp(start_timestamp)
                
                # Update title and menu
                self.title = "⏱️ ▶️"
                self.build_menu()
                self.start_timer_update()
        except Exception as e:
            print(f"Error checking existing timer: {e}")
    
    def get_elapsed_time(self) -> str:
        """Get elapsed time as formatted string."""
        if not self.tracking_start_time:
            return "00:00:00"
        
        elapsed = datetime.now() - self.tracking_start_time
        hours = int(elapsed.total_seconds() // 3600)
        minutes = int((elapsed.total_seconds() % 3600) // 60)
        seconds = int(elapsed.total_seconds() % 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    def start_timer_update(self):
        """Start the timer update loop."""
        if self.timer:
            self.timer.stop()
        
        @rumps.timer(1)
        def update_timer(sender):
            if self.current_task and self.tracking_start_time:
                elapsed = self.get_elapsed_time()
                # Update the duration menu item
                for item in self.menu.values():
                    if isinstance(item, rumps.MenuItem) and item.title.startswith("Duration:"):
                        item.title = f"Duration: {elapsed}"
                        break
        
        self.timer = update_timer
    
    @rumps.clicked("▶️ Start Tracking")
    def start_tracking(self, _):
        """Start time tracking."""
        if not self.client:
            rumps.alert("Error", "Please configure your ClickUp API token in Settings first.")
            return
        
        try:
            # Start tracking
            task_id = self.current_task.get("id") if self.current_task else None
            entry = self.client.start_time_entry(self.team_id, task_id=task_id)
            
            # Update state
            self.tracking_start_time = datetime.now()
            
            if not self.current_task:
                self.current_task = {"name": "No Task Assigned"}
            
            # Update UI
            self.title = "⏱️ ▶️"
            self.build_menu()
            self.start_timer_update()
            
        except Exception as e:
            rumps.alert("Error", f"Failed to start tracking: {str(e)}")
    
    @rumps.clicked("⏸ Pause/Stop Tracking")
    def stop_tracking(self, _):
        """Stop time tracking."""
        if not self.client:
            return
        
        try:
            # Stop tracking
            self.client.stop_time_entry(self.team_id)
            
            # Update state
            self.current_task = None
            self.tracking_start_time = None
            if self.timer:
                self.timer.stop()
                self.timer = None
            
            # Update UI
            self.title = "⏱️"
            self.build_menu()
            
            rumps.notification(
                "ClickUp Tracker",
                "Tracking Stopped",
                "Time entry has been saved to ClickUp"
            )
            
        except Exception as e:
            rumps.alert("Error", f"Failed to stop tracking: {str(e)}")
    
    @rumps.clicked("🎯 Assign Task")
    def assign_task(self, _):
        """Assign a task for tracking."""
        if not self.client:
            rumps.alert("Error", "Please configure your ClickUp API token in Settings first.")
            return
        
        # Get task ID from user
        window = rumps.Window(
            message="Enter ClickUp Task ID or search term:",
            title="Assign Task",
            default_text="",
            ok="Search",
            cancel="Cancel"
        )
        response = window.run()
        
        if response.clicked:
            task_query = response.text.strip()
            if not task_query:
                return
            
            try:
                # Try to get task by ID first
                if task_query.isdigit() or len(task_query) < 20:
                    try:
                        task = self.client.get_task(task_query)
                        self.current_task = task
                        self.build_menu()
                        rumps.notification(
                            "ClickUp Tracker",
                            "Task Assigned",
                            f"Now tracking: {task.get('name', 'Unknown')}"
                        )
                        return
                    except:
                        pass
                
                # Search for tasks
                tasks = self.client.search_tasks(self.team_id, task_query)
                
                if not tasks:
                    rumps.alert("No Results", "No tasks found matching your query.")
                    return
                
                # Show first few results
                if len(tasks) == 1:
                    self.current_task = tasks[0]
                    self.build_menu()
                    rumps.notification(
                        "ClickUp Tracker",
                        "Task Assigned",
                        f"Now tracking: {tasks[0].get('name', 'Unknown')}"
                    )
                else:
                    # For multiple results, let user pick
                    task_names = [f"{t.get('name', 'Unknown')} (ID: {t.get('id', 'N/A')})" 
                                 for t in tasks[:5]]
                    window = rumps.Window(
                        message=f"Found {len(tasks)} tasks. Enter task ID:",
                        title="Select Task",
                        default_text=tasks[0].get('id', ''),
                        ok="Select",
                        cancel="Cancel"
                    )
                    response = window.run()
                    
                    if response.clicked and response.text:
                        task_id = response.text.strip()
                        task = self.client.get_task(task_id)
                        self.current_task = task
                        self.build_menu()
                        rumps.notification(
                            "ClickUp Tracker",
                            "Task Assigned",
                            f"Now tracking: {task.get('name', 'Unknown')}"
                        )
                
            except Exception as e:
                rumps.alert("Error", f"Failed to assign task: {str(e)}")
    
    @rumps.clicked("⚙️ Settings")
    def show_settings(self, _):
        """Show settings dialog."""
        current_token = self.config.get("api_token", "")
        message = "Enter your ClickUp API Token:\n(Get it from ClickUp Settings > Apps)"
        if current_token:
            message += f"\n\nCurrent token: {current_token[:10]}..."
        
        window = rumps.Window(
            message=message,
            title="Settings",
            default_text="",
            ok="Save",
            cancel="Cancel"
        )
        response = window.run()
        
        if response.clicked:
            api_token = response.text.strip()
            if api_token:
                self.config["api_token"] = api_token
                
                # Initialize client
                try:
                    self.client = ClickUpClient(api_token)
                    user = self.client.get_user()
                    
                    # Get team ID
                    teams = self.client.get_teams()
                    if teams:
                        self.team_id = teams[0]["id"]
                        self.config["team_id"] = self.team_id
                        self.save_config()
                        self.title = "⏱️"
                        self.build_menu()
                        rumps.alert("Success", "Configuration saved successfully!")
                    else:
                        rumps.alert("Error", "No teams found for this account.")
                except Exception as e:
                    rumps.alert("Error", f"Failed to validate API token: {str(e)}")
    
    @rumps.clicked("🔄 Refresh")
    def refresh_menu(self, _):
        """Refresh the menu and check for running timers."""
        if self.client and self.team_id:
            self.check_existing_timer()
        self.build_menu()
    
    @rumps.clicked("❌ Quit")
    def quit_app(self, _):
        """Quit the application."""
        if self.current_task:
            window = rumps.Window(
                message="You have an active timer. Are you sure you want to quit?",
                title="Confirm Quit",
                ok="Quit Anyway",
                cancel="Cancel"
            )
            response = window.run()
            if not response.clicked:
                return
        
        rumps.quit_application()


if __name__ == "__main__":
    app = ClickUpTrackerApp()
    app.run()
