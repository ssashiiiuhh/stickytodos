#!/bin/bash
set -e

# Configuration
APP_NAME="StickyTodos.app"
APP_TEMPLATE="build/$APP_NAME"
RELEASE_DIR="$HOME/Downloads/StickyTodos-Releases"
DIST_DIR="dist"
LOG_FILE="$DIST_DIR/logs/release.log"
CLEAN_MODE=false

# Help
usage() {
    echo "Usage: $0 [--clean]"
    echo "  --clean  Clear dist/ directory before starting"
    exit 1
}

# Parse Args
if [[ "$1" == "--clean" ]]; then
    CLEAN_MODE=true
fi

# 1. Setup Environment
if [ "$CLEAN_MODE" = true ]; then
    echo "🧹 Cleaning dist/ directory..."
    rm -rf "$DIST_DIR"
fi

mkdir -p "$DIST_DIR/app" "$DIST_DIR/dmg" "$DIST_DIR/logs"
mkdir -p "$RELEASE_DIR"

# 2. Validation: Template existence
if [ ! -d "$APP_TEMPLATE" ]; then
    echo "❌ Error: App bundle template missing at $APP_TEMPLATE"
    exit 1
fi

# 3. Build
echo "📦 Building project..."
if ! swift build -c release > "$LOG_FILE" 2>&1; then
    echo "❌ Build failed. Check logs at $LOG_FILE"
    tail -n 10 "$LOG_FILE"
    exit 1
fi

BIN_PATH=$(swift build --show-bin-path -c release)
BIN_FILE="$BIN_PATH/StickyTodos"

# 4. Assemble Bundle
echo "🧩 Assembling bundle..."
cp -R "$APP_TEMPLATE" "$DIST_DIR/app/"
cp "$BIN_FILE" "$DIST_DIR/app/$APP_NAME/Contents/MacOS/StickyTodos"

# Inject Privacy Entitlements
plutil -insert NSRemindersUsageDescription -string "StickyTodos needs access to Reminders to sync your tasks." "$DIST_DIR/app/$APP_NAME/Contents/Info.plist" || true
plutil -insert NSRemindersFullAccessUsageDescription -string "StickyTodos needs access to Reminders to sync your tasks." "$DIST_DIR/app/$APP_NAME/Contents/Info.plist" || true
plutil -insert NSCalendarsUsageDescription -string "StickyTodos needs access to Calendars." "$DIST_DIR/app/$APP_NAME/Contents/Info.plist" || true
plutil -insert NSCalendarsFullAccessUsageDescription -string "StickyTodos needs access to Calendars." "$DIST_DIR/app/$APP_NAME/Contents/Info.plist" || true

# Verify executable
if [ ! -x "$DIST_DIR/app/$APP_NAME/Contents/MacOS/StickyTodos" ]; then
    echo "❌ Error: Binary not found or not executable in bundle."
    exit 1
fi

# 5. Replace Installed App
INSTALL_STATUS="Skipped (Manual sudo required)"
if [ -w "/Applications/$APP_NAME" ]; then
    echo "⚙️ Updating /Applications..."
    rm -rf "/Applications/$APP_NAME"
    cp -R "$DIST_DIR/app/$APP_NAME" "/Applications/"
    INSTALL_STATUS="Success"
fi

# 6. Generate DMG
echo "💿 Creating DMG..."
DMG_NAME="StickyTodos.dmg"
TEMP_DMG="$DIST_DIR/dmg/$DMG_NAME"
hdiutil create -volname "StickyTodos" -srcfolder "$DIST_DIR/app" -ov -format UDZO "$TEMP_DMG" > /dev/null

# 7. Atomically Replace DMG
mv "$TEMP_DMG" "$RELEASE_DIR/$DMG_NAME"

# 8. Summary
echo "-----------------------------------"
echo "✅ Release Summary"
echo "App Install Status : $INSTALL_STATUS"
echo "DMG Output Path    : $RELEASE_DIR/$DMG_NAME"
echo "Log Location       : $LOG_FILE"
echo "-----------------------------------"
