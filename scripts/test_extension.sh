#!/bin/bash
#
# test_extension.sh - Helper script for testing WEScaffold extension in Final Cut Pro
# Copyright © 2025 Automatic Duck, Inc.
#
# This script helps you test the WEScaffold workflow extension in Final Cut Pro

set -e

echo "=================================================="
echo "WEScaffold Extension Testing Helper"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find the built app
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."

# Check for Debug build first, then Release
DEBUG_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "WEScaffold.app" -path "*/Debug/*" 2>/dev/null | head -1)
RELEASE_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "WEScaffold.app" -path "*/Release/*" 2>/dev/null | head -1)

APP_PATH="$DEBUG_APP"
CONFIG="Debug"

if [ -z "$APP_PATH" ] && [ -n "$RELEASE_APP" ]; then
    APP_PATH="$RELEASE_APP"
    CONFIG="Release"
fi

if [ -z "$APP_PATH" ]; then
    echo -e "${YELLOW}⚠${NC} No built WEScaffold.app found"
    echo ""
    echo "Please build the project first:"
    echo "  cd $PROJECT_DIR"
    echo "  ./scripts/build.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found built app ($CONFIG): $APP_PATH"
echo ""

# Check if extension exists inside the app
APPEX_PATH="$APP_PATH/Contents/PlugIns/WEScaffoldWE.appex"
if [ -d "$APPEX_PATH" ]; then
    echo -e "${GREEN}✓${NC} Extension found: $APPEX_PATH"
else
    echo -e "${YELLOW}⚠${NC} Extension not found at: $APPEX_PATH"
    echo "The app may not have been built correctly."
    exit 1
fi
echo ""

# Check Info.plist for extension point
if [ -f "$APPEX_PATH/Contents/Info.plist" ]; then
    EXT_POINT=$(/usr/libexec/PlistBuddy -c "Print :NSExtensionPointIdentifier" "$APPEX_PATH/Contents/Info.plist" 2>/dev/null || echo "")
    if [ "$EXT_POINT" == "com.apple.FinalCut.WorkflowExtension" ]; then
        echo -e "${GREEN}✓${NC} Extension point identifier correct: $EXT_POINT"
    else
        echo -e "${YELLOW}⚠${NC} Extension point identifier: $EXT_POINT"
        echo "Expected: com.apple.FinalCut.WorkflowExtension"
    fi
else
    echo -e "${YELLOW}⚠${NC} Extension Info.plist not found"
fi
echo ""

# Check for sandboxing
if [ -f "$APPEX_PATH/Contents/Info.plist" ]; then
    SANDBOX=$(/usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" "$APPEX_PATH/Contents/Info.plist" 2>/dev/null || echo "false")
    if [ "$SANDBOX" == "true" ]; then
        echo -e "${GREEN}✓${NC} Sandboxing enabled (required for extensions)"
    else
        echo -e "${YELLOW}⚠${NC} Sandboxing NOT enabled - FCP will reject the extension"
    fi
fi
echo ""

echo "=================================================="
echo "Testing Instructions"
echo "=================================================="
echo ""
echo "1. ${BLUE}Launch Final Cut Pro${NC}"
echo "   (Make sure FCP is NOT currently running)"
echo ""
echo "2. ${BLUE}Open the extension in FCP${NC}"
echo "   Go to: Window → Extensions → WE Scaffold"
echo ""
echo "3. ${BLUE}Test drag FROM FCP TO extension${NC}"
echo "   - Create a simple project in FCP if needed"
echo "   - Drag a project/event/clip from FCP browser onto the drop zone"
echo "   - Check that status updates to show XML received"
echo ""
echo "4. ${BLUE}Test drag FROM extension TO FCP${NC}"
echo "   - After dropping XML, drag from the drag box back to FCP timeline"
echo "   - Verify the clip appears in the timeline"
echo ""
echo "5. ${BLUE}Check logs${NC}"
echo "   Open Console.app and filter for 'WEScaffold'"
echo "   Or view file log:"
echo "   tail -f ~/Library/Logs/WEScaffold/wescaffold.log"
echo ""

echo "=================================================="
echo "Troubleshooting"
echo "=================================================="
echo ""
echo "Extension doesn't appear in FCP Extensions menu:"
echo "  • Check Console.app for FCP errors"
echo "  • Verify sandboxing is enabled (see above)"
echo "  • Restart Final Cut Pro"
echo "  • Check extension point identifier (see above)"
echo ""
echo "Drop doesn't work:"
echo "  • Check Console logs for [DROP] messages"
echo "  • Verify you're dragging a valid FCP item (project/event/clip)"
echo ""
echo "Drag back fails:"
echo "  • Must drop XML first before dragging"
echo "  • Check logs for [DRAG] promise messages"
echo ""

# Offer to open log directory
echo "=================================================="
echo ""
read -p "Open log directory now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    LOG_DIR="$HOME/Library/Logs/WEScaffold"
    mkdir -p "$LOG_DIR"
    open "$LOG_DIR"
    echo "Log directory opened: $LOG_DIR"
fi
echo ""

# Offer to launch FCP
read -p "Launch Final Cut Pro now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "/Applications/Final Cut Pro.app" ]; then
        echo "Launching Final Cut Pro..."
        open "/Applications/Final Cut Pro.app"
    else
        echo "Final Cut Pro not found at /Applications/Final Cut Pro.app"
    fi
fi

echo ""
echo "Happy testing!"
