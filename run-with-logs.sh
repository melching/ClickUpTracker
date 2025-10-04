#!/bin/bash

# Script to run ClickUpTracker with full console logging
# This helps debug API issues by showing all print() statements

echo "🔍 Starting ClickUpTracker with logging enabled..."
echo "📋 All API calls and responses will be shown below"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the app and show all output
./ClickUpTracker.app/Contents/MacOS/ClickUpTracker 2>&1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ App closed"
