#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/LiquidTetris.app"
BINARY="$DIR/.build/arm64-apple-macosx/debug/LiquidTetris"

# Kill existing
pkill -f LiquidTetris 2>/dev/null || true
sleep 0.5

# Build
cd "$DIR"
echo "Building..."
swift build 2>&1 | tail -1

# Create .app bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BINARY" "$APP/Contents/MacOS/"
cp "$DIR/Info.plist" "$APP/Contents/Info.plist"

# Launch
echo "Launching LiquidTetris..."
open "$APP"
