#!/bin/bash
#
# validate_build.sh - Validate WEScaffold build configuration
# Copyright © 2025 Automatic Duck, Inc.
#
# This script checks that all prerequisites are in place before building

set -e

echo "=================================================="
echo "WEScaffold Build Validation"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS=0
WARNINGS=0
FAILURES=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILURES++))
}

echo "=== Checking Xcode Installation ==="
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    check_pass "Xcode found: $XCODE_VERSION"
else
    check_fail "Xcode not found - install from App Store"
fi

if command -v xcode-select &> /dev/null; then
    XCODE_PATH=$(xcode-select -p)
    check_pass "Xcode path: $XCODE_PATH"
else
    check_fail "xcode-select not found"
fi
echo ""

echo "=== Checking Project Structure ==="
if [ -f "mac/WEScaffold.xcodeproj/project.pbxproj" ]; then
    check_pass "Xcode project file exists"
else
    check_fail "Xcode project file missing: mac/WEScaffold.xcodeproj/project.pbxproj"
fi

if [ -f "rsrc/Base.lproj/WEScaffold.xib" ]; then
    check_pass "App XIB file exists"
else
    check_fail "App XIB missing: rsrc/Base.lproj/WEScaffold.xib"
fi

if [ -f "rsrc/Base.lproj/WEScaffoldWE.xib" ]; then
    check_pass "Extension XIB file exists"
else
    check_fail "Extension XIB missing: rsrc/Base.lproj/WEScaffoldWE.xib"
fi
echo ""

echo "=== Checking Source Files ==="
SOURCE_FILES=(
    "src/WEScaffoldGlobals.h"
    "src/WEScaffoldGlobals.cpp"
    "src/main.cpp"
    "src/WEScaffoldController.h"
    "src/WEScaffoldController.mm"
    "src/WEScaffoldWindowDelegate.h"
    "src/WEScaffoldWindowDelegate.mm"
    "src/WEScaffoldDropButton.h"
    "src/WEScaffoldDropButton.mm"
    "src/WEScaffoldDragBox.h"
    "src/WEScaffoldDragBox.mm"
)

for file in "${SOURCE_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file"
    else
        check_fail "Missing: $file"
    fi
done
echo ""

echo "=== Checking Configuration Files ==="
CONFIG_FILES=(
    "mac/Info.plist"
    "mac/WEScaffold.entitlements"
    "mac/WEScaffoldWE/Info.plist"
    "mac/WEScaffoldWE.entitlements"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file"
    else
        check_fail "Missing: $file"
    fi
done
echo ""

echo "=== Checking Parent AutomaticDuckII Repository ==="
AD_PATH="$HOME/dev/AutomaticDuckII"
if [ -d "$AD_PATH" ]; then
    check_pass "AutomaticDuckII found at $AD_PATH"
else
    check_fail "AutomaticDuckII not found at $AD_PATH"
fi

AD_SHARE_PATH="$AD_PATH/share"
if [ -d "$AD_SHARE_PATH" ]; then
    check_pass "Shared libraries path exists"

    # Check key shared headers
    if [ -f "$AD_SHARE_PATH/xml/DuckXmlDoc.h" ]; then
        check_pass "DuckXmlDoc.h found"
    else
        check_warn "DuckXmlDoc.h not found (may need to build shared lib)"
    fi

    if [ -f "$AD_SHARE_PATH/plog.h" ]; then
        check_pass "plog.h found"
    else
        check_warn "plog.h not found"
    fi
else
    check_fail "Shared libraries path missing: $AD_SHARE_PATH"
fi
echo ""

echo "=== Checking System Frameworks ==="
if [ -d "/System/Library/Frameworks/Cocoa.framework" ]; then
    check_pass "Cocoa.framework found"
else
    check_fail "Cocoa.framework missing"
fi

if [ -d "/System/Library/Frameworks/QuartzCore.framework" ]; then
    check_pass "QuartzCore.framework found"
else
    check_fail "QuartzCore.framework missing"
fi

if [ -d "/System/Library/PrivateFrameworks/ProExtension.framework" ]; then
    check_pass "ProExtension.framework found (required for extension)"
else
    check_warn "ProExtension.framework not found - extension may not load in FCP"
fi

if [ -f "/usr/lib/libxml2.tbd" ] || [ -f "/usr/lib/libxml2.dylib" ]; then
    check_pass "libxml2 found"
else
    check_fail "libxml2 not found"
fi

if [ -d "/usr/include/libxml2" ]; then
    check_pass "libxml2 headers found"
else
    check_fail "libxml2 headers missing at /usr/include/libxml2"
fi
echo ""

echo "=== Checking Info.plist Configuration ==="
if [ -f "mac/WEScaffoldWE/Info.plist" ]; then
    if grep -q "com.apple.FinalCut.WorkflowExtension" "mac/WEScaffoldWE/Info.plist"; then
        check_pass "Extension point identifier configured correctly"
    else
        check_fail "NSExtensionPointIdentifier not set to com.apple.FinalCut.WorkflowExtension"
    fi
fi
echo ""

echo "=================================================="
echo "Summary:"
echo "  ✓ Passed:  $SUCCESS"
echo "  ⚠ Warnings: $WARNINGS"
echo "  ✗ Failed:  $FAILURES"
echo "=================================================="
echo ""

if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}Build validation FAILED${NC} - fix errors above before building"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Build validation passed with warnings${NC} - review warnings above"
    exit 0
else
    echo -e "${GREEN}Build validation PASSED${NC} - ready to build!"
    exit 0
fi
