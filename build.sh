#!/bin/bash

# ClickUpTracker Build Script
# This script builds and runs the ClickUpTracker app

set -e  # Exit on error

echo "🚀 ClickUpTracker Build Script"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found!"
    echo "Please run this script from the ClickUpTracker directory."
    exit 1
fi

echo -e "${BLUE}Step 1:${NC} Cleaning previous builds..."
swift package clean
echo -e "${GREEN}✓${NC} Clean complete"
echo ""

echo -e "${BLUE}Step 2:${NC} Building the application..."
swift build -c release 2>&1 | grep -v "warning: initialization of immutable value" || true
BUILD_EXIT_CODE=${PIPESTATUS[0]}

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Build successful!"
else
    echo "❌ Build failed!"
    echo "Check the error messages above."
    exit 1
fi
echo ""

echo -e "${BLUE}Step 3:${NC} Application ready!"
echo ""
echo "📍 Executable location:"
echo "   $(pwd)/.build/release/ClickUpTracker"
echo ""

# Ask user if they want to run the app
read -p "$(echo -e ${YELLOW}Would you like to run the app now? [y/N]:${NC} )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}🎉 Starting ClickUpTracker...${NC}"
    echo "   (Look for the clock icon in your menu bar)"
    echo ""
    ./.build/release/ClickUpTracker
else
    echo ""
    echo "To run the app later, use:"
    echo "   ./.build/release/ClickUpTracker"
    echo ""
    echo "Or open in Xcode:"
    echo "   open Package.swift"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
