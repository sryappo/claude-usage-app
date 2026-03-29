#!/bin/bash
set -euo pipefail

APP_NAME="ClaudeUsage"
BUILD_DIR=".build"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"

echo "Building $APP_NAME…"
swift build -c release --arch arm64 2>&1

echo "Creating app bundle…"
rm -rf "$APP_BUNDLE"
RESOURCES_DIR="$CONTENTS/Resources"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp "$BUILD_DIR/arm64-apple-macosx/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
    echo "  ✓ Added app icon"
fi

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClaudeUsage</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.claude-usage</string>
    <key>CFBundleName</key>
    <string>Claude Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Usage</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✓ Built $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install:  cp -r $APP_BUNDLE /Applications/"
