"""
Example script demonstrating how to use the ClickUp client directly.
This can be useful for automation or integration with other tools.
"""

from clickup_client import ClickUpClient
import json
import os


def load_config():
    """Load configuration from config.json."""
    config_path = "config.json"
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            return json.load(f)
    else:
        print("Error: config.json not found. Please create it from config.example.json")
        return None


def main():
    """Main example function."""
    # Load config
    config = load_config()
    if not config or not config.get("api_token"):
        return
    
    # Initialize client
    client = ClickUpClient(config["api_token"])
    team_id = config.get("team_id")
    
    print("ClickUp Client Example")
    print("=" * 50)
    
    # Get user info
    print("\n1. Getting user information...")
    user = client.get_user()
    print(f"   Logged in as: {user['user']['username']}")
    print(f"   Email: {user['user']['email']}")
    
    # Get teams
    print("\n2. Getting teams...")
    teams = client.get_teams()
    for team in teams:
        print(f"   - {team['name']} (ID: {team['id']})")
    
    # Check for running timer
    print("\n3. Checking for running time entry...")
    running = client.get_running_time_entry(team_id)
    if running:
        print(f"   ✓ Timer is running!")
        task_id = running.get("task", {}).get("id")
        if task_id:
            print(f"   Task ID: {task_id}")
    else:
        print("   No timer currently running")
    
    # Example: Search for tasks
    print("\n4. Example: Search for tasks")
    search_term = input("   Enter search term (or press Enter to skip): ").strip()
    if search_term:
        tasks = client.search_tasks(team_id, search_term)
        print(f"   Found {len(tasks)} tasks:")
        for task in tasks[:5]:  # Show first 5
            print(f"   - {task['name']} (ID: {task['id']})")
    
    print("\n" + "=" * 50)
    print("Example complete!")
    print("\nYou can use these methods in your own scripts:")
    print("  - client.start_time_entry(team_id, task_id)")
    print("  - client.stop_time_entry(team_id)")
    print("  - client.get_task(task_id)")
    print("  - client.search_tasks(team_id, query)")
    print("\nSee clickup_client.py for all available methods.")


if __name__ == "__main__":
    main()
