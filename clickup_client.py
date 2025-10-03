"""
ClickUp API client for time tracking operations.
"""

import requests
from typing import Optional, Dict, List, Any
from datetime import datetime


class ClickUpClient:
    """Client for interacting with ClickUp API."""
    
    BASE_URL = "https://api.clickup.com/api/v2"
    
    def __init__(self, api_token: str):
        """
        Initialize ClickUp client.
        
        Args:
            api_token: ClickUp API token
        """
        self.api_token = api_token
        self.headers = {
            "Authorization": api_token,
            "Content-Type": "application/json"
        }
    
    def get_user(self) -> Dict[str, Any]:
        """
        Get authenticated user information.
        
        Returns:
            User information dictionary
        """
        response = requests.get(
            f"{self.BASE_URL}/user",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_teams(self) -> List[Dict[str, Any]]:
        """
        Get all teams (workspaces) for the authenticated user.
        
        Returns:
            List of team dictionaries
        """
        response = requests.get(
            f"{self.BASE_URL}/team",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json().get("teams", [])
    
    def get_spaces(self, team_id: str) -> List[Dict[str, Any]]:
        """
        Get all spaces in a team.
        
        Args:
            team_id: Team ID
            
        Returns:
            List of space dictionaries
        """
        response = requests.get(
            f"{self.BASE_URL}/team/{team_id}/space",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json().get("spaces", [])
    
    def get_lists(self, space_id: str) -> List[Dict[str, Any]]:
        """
        Get all lists in a space.
        
        Args:
            space_id: Space ID
            
        Returns:
            List of list dictionaries
        """
        response = requests.get(
            f"{self.BASE_URL}/space/{space_id}/list",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json().get("lists", [])
    
    def get_tasks(self, list_id: str) -> List[Dict[str, Any]]:
        """
        Get all tasks in a list.
        
        Args:
            list_id: List ID
            
        Returns:
            List of task dictionaries
        """
        response = requests.get(
            f"{self.BASE_URL}/list/{list_id}/task",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json().get("tasks", [])
    
    def get_running_time_entry(self, team_id: str) -> Optional[Dict[str, Any]]:
        """
        Get currently running time entry for the user.
        
        Args:
            team_id: Team ID
            
        Returns:
            Time entry dictionary if running, None otherwise
        """
        response = requests.get(
            f"{self.BASE_URL}/team/{team_id}/time_entries/current",
            headers=self.headers
        )
        response.raise_for_status()
        data = response.json()
        return data.get("data") if data.get("data") else None
    
    def start_time_entry(self, team_id: str, task_id: Optional[str] = None, 
                        description: Optional[str] = None) -> Dict[str, Any]:
        """
        Start a new time entry.
        
        Args:
            team_id: Team ID
            task_id: Optional task ID to track time for
            description: Optional description
            
        Returns:
            Created time entry dictionary
        """
        data = {
            "description": description or "",
            "billable": False
        }
        
        if task_id:
            data["tid"] = task_id
        
        response = requests.post(
            f"{self.BASE_URL}/team/{team_id}/time_entries/start",
            headers=self.headers,
            json=data
        )
        response.raise_for_status()
        return response.json().get("data", {})
    
    def stop_time_entry(self, team_id: str) -> Dict[str, Any]:
        """
        Stop the currently running time entry.
        
        Args:
            team_id: Team ID
            
        Returns:
            Stopped time entry dictionary
        """
        response = requests.post(
            f"{self.BASE_URL}/team/{team_id}/time_entries/stop",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json().get("data", {})
    
    def get_task(self, task_id: str) -> Dict[str, Any]:
        """
        Get task details.
        
        Args:
            task_id: Task ID
            
        Returns:
            Task dictionary
        """
        response = requests.get(
            f"{self.BASE_URL}/task/{task_id}",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def search_tasks(self, team_id: str, query: str) -> List[Dict[str, Any]]:
        """
        Search for tasks by name.
        
        Args:
            team_id: Team ID
            query: Search query
            
        Returns:
            List of matching task dictionaries
        """
        response = requests.get(
            f"{self.BASE_URL}/team/{team_id}/task",
            headers=self.headers,
            params={"search": query}
        )
        response.raise_for_status()
        return response.json().get("tasks", [])
