"""
Basic tests for ClickUp Tracker components.
These tests validate the structure without requiring actual API access.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(__file__))

from clickup_client import ClickUpClient


class TestClickUpClient(unittest.TestCase):
    """Test cases for ClickUpClient."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.api_token = "test_token_123"
        self.client = ClickUpClient(self.api_token)
    
    def test_client_initialization(self):
        """Test client initializes with correct token."""
        self.assertEqual(self.client.api_token, self.api_token)
        self.assertIn("Authorization", self.client.headers)
        self.assertEqual(self.client.headers["Authorization"], self.api_token)
    
    def test_base_url(self):
        """Test base URL is correct."""
        self.assertEqual(self.client.BASE_URL, "https://api.clickup.com/api/v2")
    
    @patch('clickup_client.requests.get')
    def test_get_user(self, mock_get):
        """Test get_user makes correct API call."""
        mock_response = Mock()
        mock_response.json.return_value = {"user": {"id": "123", "username": "test"}}
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        result = self.client.get_user()
        
        mock_get.assert_called_once()
        self.assertEqual(result["user"]["username"], "test")
    
    @patch('clickup_client.requests.get')
    def test_get_teams(self, mock_get):
        """Test get_teams makes correct API call."""
        mock_response = Mock()
        mock_response.json.return_value = {"teams": [{"id": "team1", "name": "Test Team"}]}
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        result = self.client.get_teams()
        
        mock_get.assert_called_once()
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["name"], "Test Team")
    
    @patch('clickup_client.requests.post')
    def test_start_time_entry(self, mock_post):
        """Test start_time_entry makes correct API call."""
        mock_response = Mock()
        mock_response.json.return_value = {"data": {"id": "entry123"}}
        mock_response.raise_for_status = Mock()
        mock_post.return_value = mock_response
        
        team_id = "team123"
        task_id = "task456"
        result = self.client.start_time_entry(team_id, task_id)
        
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        self.assertIn(f"team/{team_id}/time_entries/start", call_args[0][0])
        self.assertEqual(call_args[1]["json"]["tid"], task_id)
    
    @patch('clickup_client.requests.post')
    def test_stop_time_entry(self, mock_post):
        """Test stop_time_entry makes correct API call."""
        mock_response = Mock()
        mock_response.json.return_value = {"data": {"id": "entry123"}}
        mock_response.raise_for_status = Mock()
        mock_post.return_value = mock_response
        
        team_id = "team123"
        result = self.client.stop_time_entry(team_id)
        
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        self.assertIn(f"team/{team_id}/time_entries/stop", call_args[0][0])
    
    @patch('clickup_client.requests.get')
    def test_get_running_time_entry_none(self, mock_get):
        """Test get_running_time_entry when no timer is running."""
        mock_response = Mock()
        mock_response.json.return_value = {"data": None}
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        result = self.client.get_running_time_entry("team123")
        
        self.assertIsNone(result)
    
    @patch('clickup_client.requests.get')
    def test_get_running_time_entry_active(self, mock_get):
        """Test get_running_time_entry when timer is running."""
        mock_response = Mock()
        mock_response.json.return_value = {"data": {"id": "entry123", "start": 1234567890}}
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        result = self.client.get_running_time_entry("team123")
        
        self.assertIsNotNone(result)
        self.assertEqual(result["id"], "entry123")


class TestConfiguration(unittest.TestCase):
    """Test configuration handling."""
    
    def test_config_example_exists(self):
        """Test that config.example.json exists."""
        config_path = os.path.join(os.path.dirname(__file__), "config.example.json")
        self.assertTrue(os.path.exists(config_path))
    
    def test_gitignore_exists(self):
        """Test that .gitignore exists."""
        gitignore_path = os.path.join(os.path.dirname(__file__), ".gitignore")
        self.assertTrue(os.path.exists(gitignore_path))
    
    def test_requirements_exists(self):
        """Test that requirements.txt exists."""
        req_path = os.path.join(os.path.dirname(__file__), "requirements.txt")
        self.assertTrue(os.path.exists(req_path))
        
        # Check it contains required packages
        with open(req_path, 'r') as f:
            content = f.read()
            self.assertIn("rumps", content)
            self.assertIn("requests", content)


class TestProjectStructure(unittest.TestCase):
    """Test project structure and files."""
    
    def test_main_files_exist(self):
        """Test that main application files exist."""
        base_path = os.path.dirname(__file__)
        
        required_files = [
            "clickup_tracker.py",
            "clickup_client.py",
            "requirements.txt",
            "README.md",
            "setup.sh"
        ]
        
        for filename in required_files:
            file_path = os.path.join(base_path, filename)
            self.assertTrue(os.path.exists(file_path), f"{filename} should exist")
    
    def test_documentation_exists(self):
        """Test that documentation files exist."""
        base_path = os.path.dirname(__file__)
        
        doc_files = ["README.md", "QUICKSTART.md"]
        
        for filename in doc_files:
            file_path = os.path.join(base_path, filename)
            self.assertTrue(os.path.exists(file_path), f"{filename} should exist")


if __name__ == "__main__":
    print("Running ClickUp Tracker Tests")
    print("=" * 50)
    unittest.main(verbosity=2)
