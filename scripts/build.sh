#!/bin/bash
#
# build.sh - Build WEScaffold app and extension
# Copyright © 2025 Automatic Duck, Inc.
#
# Usage:
#   ./build.sh          # Build Debug configuration
#   ./build.sh release  # Build Release configuration

set -e

# Determine configuration
CONFIG="${1:-Debug}"
if [ "$CONFIG" != "Debug" ] && [ "$CONFIG" != "Release" ]; then
    echo "Error: Configuration must be 'Debug' or 'Release'"
    echo "Usage: $0 [Debug|Release]"
    exit 1
fi

echo "=================================================="
echo "Building WEScaffold - $CONFIG Configuration"
echo "=================================================="
echo ""

# Navigate to project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/.."
cd "$PROJECT_DIR"

# Run validation first
echo "Running pre-build validation..."
if ./scripts/validate_build.sh; then
    echo ""
    echo "Validation passed, proceeding with build..."
    echo ""
else
    echo ""
    echo "Validation failed - fix errors before building"
    exit 1
fi

# Build using xcodebuild
XCODEPROJ="mac/WEScaffold.xcodeproj"
SCHEME="WEScaffold"

echo "Building project..."
echo "  Project: $XCODEPROJ"
echo "  Scheme: $SCHEME"
echo "  Configuration: $CONFIG"
echo ""

xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    clean build \
    | tee "build_${CONFIG}.log"

# Check build result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "=================================================="
    echo "✓ Build succeeded!"
    echo "=================================================="
    echo ""

    # Find the built products
    BUILD_DIR=$(xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration "$CONFIG" -showBuildSettings | grep " BUILD_DIR =" | sed 's/.*= //')
    APP_PATH="$BUILD_DIR/$CONFIG/WEScaffold.app"
    APPEX_PATH="$APP_PATH/Contents/PlugIns/WEScaffoldWE.appex"

    echo "Build products:"
    if [ -d "$APP_PATH" ]; then
        echo "  App: $APP_PATH"
        ls -lh "$APP_PATH/Contents/MacOS/WEScaffold" || true
    fi

    if [ -d "$APPEX_PATH" ]; then
        echo "  Extension: $APPEX_PATH"
        ls -lh "$APPEX_PATH/Contents/MacOS/WEScaffoldWE" || true
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Run standalone app: open \"$APP_PATH\""
    echo "  2. Test in Final Cut Pro: ./scripts/test_extension.sh"
    echo "  3. View logs: tail -f ~/Library/Logs/WEScaffold/wescaffold.log"
    echo ""
else
    echo ""
    echo "=================================================="
    echo "✗ Build FAILED"
    echo "=================================================="
    echo ""
    echo "Check build_${CONFIG}.log for details"
    exit 1
fi
