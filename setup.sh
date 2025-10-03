#!/bin/bash
# Setup script for ClickUp Tracker

echo "ClickUp Tracker Setup"
echo "===================="
echo ""

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Found Python $python_version"

# Install dependencies
echo ""
echo "Installing dependencies..."
pip3 install -r requirements.txt

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
