#!/bin/bash
# Setup script for ClickUp Tracker

echo "ClickUp Tracker Setup"
echo "===================="
echo ""

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Found Python $python_version"

# Check if Python 3.12+ is available
major_version=$(echo $python_version | cut -d. -f1)
minor_version=$(echo $python_version | cut -d. -f2)
if [ "$major_version" -lt 3 ] || ([ "$major_version" -eq 3 ] && [ "$minor_version" -lt 12 ]); then
    echo "⚠️  Warning: Python 3.12 or higher is recommended"
    echo "   Current version: $python_version"
fi

# Install uv if not available
echo ""
if ! command -v uv &> /dev/null; then
    echo "Installing uv package manager..."
    pip3 install uv
else
    echo "✓ uv is already installed"
fi

# Install dependencies
echo ""
echo "Installing dependencies with uv..."
uv pip install -r requirements.txt

# Create config if it doesn't exist
if [ ! -f "config.json" ]; then
    echo ""
    echo "Creating config.json from example..."
    cp config.example.json config.json
    echo "✓ Config file created. Please edit config.json with your ClickUp API token."
else
    echo ""
    echo "✓ Config file already exists."
fi

echo ""
echo "Setup complete! Run the app with:"
echo "  python3 clickup_tracker.py"
echo ""
echo "Note: You'll need to add your ClickUp API token either by:"
echo "  1. Editing config.json manually, or"
echo "  2. Using the Settings menu in the app"
