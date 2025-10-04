#!/bin/bash

# Script to create a proper .app bundle from the Swift executable
# This enables full functionality including notifications

set -e

echo "📦 Creating ClickUpTracker.app bundle..."
echo ""

# Build the release executable
echo "Step 1: Building executable..."
swift build -c release
echo "✓ Build complete"
echo ""

# Create app bundle structure
echo "Step 2: Creating .app bundle structure..."
APP_DIR="ClickUpTracker.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
echo "✓ Structure created"
echo ""

# Copy executable
echo "Step 3: Copying executable..."
cp .build/release/ClickUpTracker "$APP_DIR/Contents/MacOS/"
chmod +x "$APP_DIR/Contents/MacOS/ClickUpTracker"
echo "✓ Executable copied"
echo ""

# Copy Info.plist
echo "Step 4: Copying Info.plist..."
cp Info.plist "$APP_DIR/Contents/"

# Fix the Info.plist - replace Xcode variables with actual values
sed -i '' 's/$(DEVELOPMENT_LANGUAGE)/en/g' "$APP_DIR/Contents/Info.plist"
sed -i '' 's/$(EXECUTABLE_NAME)/ClickUpTracker/g' "$APP_DIR/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_NAME)/ClickUpTracker/g' "$APP_DIR/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' "$APP_DIR/Contents/Info.plist"
sed -i '' 's/$(MACOSX_DEPLOYMENT_TARGET)/14.0/g' "$APP_DIR/Contents/Info.plist"

echo "✓ Info.plist copied and fixed"
echo ""

# Create a proper bundle identifier in Info.plist
echo "Step 5: Updating bundle identifier..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.clickuptracker.app" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.clickuptracker.app" "$APP_DIR/Contents/Info.plist"
echo "✓ Bundle identifier set"
echo ""

echo "✅ Success! ClickUpTracker.app created"
echo ""
echo "📍 Location: $(pwd)/ClickUpTracker.app"
echo ""
echo "To run the app:"
echo "   open ClickUpTracker.app"
echo ""
echo "To install to Applications:"
echo "   cp -r ClickUpTracker.app /Applications/"
echo ""
echo "Note: With the .app bundle, all features work including:"
echo "  ✓ Menu bar icon (no Dock icon)"
echo "  ✓ System notifications"
echo "  ✓ Proper macOS integration"
