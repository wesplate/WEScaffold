# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

WEScaffold is an educational template for building Final Cut Pro X Workflow Extensions. It demonstrates the complete bidirectional drag-and-drop pattern needed for all FCPXML-based Workflow Extensions: receiving FCPXML from FCP and sending it back.

This is a **dual-mode application**:
- **Standalone macOS app** (WEScaffold.app) - Shows instructions to user
- **Embedded Workflow Extension** (WEScaffoldWE.appex) - Runs inside Final Cut Pro

The scaffold is a pass-through (XML in = XML out, unchanged). Developers copy this template and add their own processing logic between receiving and returning the XML.

## Project Status

**Source Code:** 100% complete - all `.h`, `.mm`, `.cpp` files ready
**Xcode Project:** Not created - requires manual setup in Xcode GUI
**Build Status:** Buildable once Xcode project is configured per `XCODE_SETUP_GUIDE.md`

## Building the Project

### Prerequisites

- Xcode 14+ with Command Line Tools
- Parent AutomaticDuckII repository at `~/AutomaticDuckII`
- Automatic Duck shared libraries built (`duckShareARMLib`)

### Current Build Process

**IMPORTANT:** There is no `.xcodeproj` file yet. The Xcode project must be created manually following the comprehensive guide:

```bash
# Read the setup guide
open XCODE_SETUP_GUIDE.md
```

The guide walks through:
1. Creating the Xcode project with dual targets (app + extension)
2. Configuring build settings and linking frameworks
3. Adding source files to appropriate targets
4. Creating XIB files in Interface Builder
5. Building and testing in Final Cut Pro

**Estimated setup time:** 1.5-2 hours for first-time setup

### Dependencies on Parent Repository

WEScaffold requires these components from `~/AutomaticDuckII`:

**Header Search Paths:**
```
$(HOME)/AutomaticDuckII/share
$(HOME)/AutomaticDuckII/share/xml
$(HOME)/AutomaticDuckII/share/files
$(HOME)/AutomaticDuckII/share/str
/usr/include/libxml2
```

**Key Shared Libraries Used:**
- `DuckXmlDoc` / `DuckNode` - FCPXML parsing (libxml2 wrapper)
- `plog` - File logging system
- `DFile` - Cross-platform file path handling
- `DRational` / `DEditRate` - Frame-accurate timecode math

### Build Targets

**WEScaffold (macOS App):**
- Product type: `com.apple.product-type.application`
- Entry point: `main.cpp` with `NSApplicationMain()`
- Preprocessor: `AD=$(HOME)/AutomaticDuckII`
- XIB: `WEScaffold.xib`

**WEScaffoldWE (App Extension):**
- Product type: `com.apple.product-type.app-extension`
- Entry point: `ProExtensionMain` (no `main()` function)
- Preprocessor: `WORKFLOW_EXTENSION=1`, `AD=$(HOME)/AutomaticDuckII`
- XIB: `WEScaffoldWE.xib`
- Additional linker flags: `-lProExtension -u _ProExtensionMain`
- Framework search path: `/System/Library/PrivateFrameworks`
- **CRITICAL:** `main.cpp` must be excluded from this target

### Testing

**Standalone App:**
```bash
# After Xcode project is built
open ~/Library/Developer/Xcode/DerivedData/WEScaffold-*/Build/Products/Debug/WEScaffold.app
```

**Workflow Extension:**
1. Build project in Xcode (builds both app and extension)
2. Launch Final Cut Pro
3. Window → Extensions → WE Scaffold
4. Drag a project/event/clip from FCP browser onto the drop zone
5. Drag from the drag zone back to FCP timeline
6. Verify XML is unchanged

**Viewing Logs:**
```bash
# Real-time console logs
open /System/Applications/Utilities/Console.app
# Filter for "WEScaffold"

# File logs
tail -f ~/Library/Logs/WEScaffold/wescaffold.log
```

## Architecture

### Dual-Mode Compilation

The same source files compile into two different binaries using conditional compilation:

```cpp
#if WORKFLOW_EXTENSION
    // Extension-specific code (runs in FCP's process)
    - (NSString*)nibName { return @"WEScaffoldWE"; }
#else
    // Standalone app code
    int main(int argc, char* argv[]) {
        return NSApplicationMain(argc, argv);
    }
#endif
```

This pattern allows shared logic between app and extension while handling their different lifecycles.

### Data Flow Pattern

```
Final Cut Pro
    │
    │ (1) User drags project
    ↓
WEScaffoldDropButton (NSDraggingDestination)
    │ Extract NSData from pasteboard
    │ Validate type: com.apple.finalcutpro.xml
    ↓
WEScaffoldController
    │ receiveXMLData:
    ↓
WEScaffoldGlobals (Global State)
    │ xmlData = CFRetain(data)
    ↓
WEScaffoldDragBox (NSDraggingSource)
    │ mouseDown: creates promise
    │ provideDataForType: fulfills promise
    ↓
Final Cut Pro
```

### The Promise Pattern

**Critical for performance with large FCPXML files (100MB+):**

```objc
// Step 1: mouseDown: - Create promise (no data copied yet)
NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];
[pbItem setDataProvider:self forTypes:@[FCP_XML_PBOARD_TYPE]];
[self beginDraggingSessionWithItems:@[dragItem] event:theEvent source:self];

// Step 2: provideDataForType: - Fulfill promise (only if FCP accepts drop)
- (void)pasteboard:(NSPasteboard*)pasteboard
              item:(NSPasteboardItem*)item
provideDataForType:(NSPasteboardType)type {
    NSData* xmlData = [controller provideDragData];
    [item setData:xmlData forType:type];  // NOW copy the data
}
```

If user cancels drag or drops on invalid target, Step 2 never happens - no data copied!

### Memory Management

Uses `CFDataRef` instead of `NSData*` for educational purposes (explicit retain/release):

```cpp
// Store (retain)
xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);

// Retrieve (toll-free bridging)
NSData* data = (NSData*)xGlobals.xmlData;

// Release (cleanup)
if (xGlobals.xmlData) {
    CFRelease(xGlobals.xmlData);
    xGlobals.xmlData = NULL;
}
```

This teaches explicit ownership and works in both C++ and Objective-C code.

### Extension Lifecycle

**Discovery:** FCP scans for `.appex` bundles in `Contents/PlugIns/` with `NSExtensionPointIdentifier = com.apple.FinalCut.WorkflowExtension`

**Loading:** User selects Window → Extensions → WE Scaffold
```
ProExtensionMain called (entry point)
    ↓
NSViewController instantiated
    ↓
viewDidLoad (XIB loaded, outlets connected)
    ↓
viewWillAppear (GET WINDOW REFERENCE HERE - FCP created it)
    ↓
Extension visible to user
```

**Critical:** In extension mode, you cannot create the window - FCP creates it. You must get the window reference in `viewWillAppear`:
```objc
- (void)viewWillAppear {
    [super viewWillAppear];
    myWindow = [self.view window];  // NOW we have it
}
```

## Key Files and Their Responsibilities

| File | Purpose | Protocols |
|------|---------|-----------|
| `WEScaffoldGlobals.h/cpp` | Global state, logging macros, initialize/cleanup | - |
| `main.cpp` | App entry point (excluded from extension target) | - |
| `WEScaffoldController.mm` | Main view controller, coordinator between drop/drag | `NSViewController` |
| `WEScaffoldDropButton.mm` | Receives FCPXML from FCP | `NSDraggingDestination` |
| `WEScaffoldDragBox.mm` | Sends FCPXML back to FCP | `NSDraggingSource`, `NSPasteboardItemDataProvider` |
| `WEScaffoldWindowDelegate.mm` | Window resize handling | `NSWindowDelegate` |

## Integration with AutomaticDuckII Shared Libraries

### XML Parsing Example
```cpp
#include "DuckXmlDoc.h"

DuckXmlDoc doc;
if (doc.Parse((const char*)CFDataGetBytePtr(xGlobals.xmlData),
              CFDataGetLength(xGlobals.xmlData))) {
    DuckNode* root = doc.RootNode();
    const char* elementName = root->Name();
    // Process nodes...
}
```

### File Logging Example
```cpp
#include "plog.h"

xGlobals.syslog = fopen(logPathCStr, "w");
fprintf(xGlobals.syslog, "[EVENT] Something happened\n");
fflush(xGlobals.syslog);
```

### Path Handling Example
```cpp
#include "DFile.h"

DFile logPath;
logPath.assign("~/Library/Logs/WEScaffold/wescaffold.log", DFILEPATH_POSIX);
const char* expandedPath = logPath.c_str();
```

## Sandboxing Requirements

**CRITICAL:** All App Extensions must be sandboxed or FCP will reject them.

**Minimum entitlements required:**
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

Already configured in:
- `mac/WEScaffold.entitlements` (app)
- `mac/WEScaffoldWE.entitlements` (extension)

## Logging System

### Educational Macros

All operations are extensively logged using categorized macros:

```cpp
LIFECYCLE_LOG("viewDidLoad called");
DROP_LOG("Received %ld bytes of XML", [xmlData length]);
DRAG_LOG("Promise fulfilled successfully!");
DATA_LOG("Valid FCPXML: root element = %s", doc.RootNode()->Name());
ERROR_LOG("Failed to parse XML");
```

**Categories:** `[LIFECYCLE]`, `[DROP]`, `[DRAG]`, `[DATA]`, `[ERROR]`

**Output destinations:**
1. NSLog → Xcode console, Console.app, FCP console
2. File → `~/Library/Logs/WEScaffold/wescaffold.log`

See `LOGGING.md` for complete log interpretation guide.

## Using as a Template

### Adding Custom XML Processing

**Current (pass-through):**
```objc
- (void)receiveXMLData:(NSData*)xmlData {
    xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);
}
```

**With processing:**
```objc
- (void)receiveXMLData:(NSData*)xmlData {
    // Store original
    xGlobals.inputXML = (CFDataRef)CFRetain((CFDataRef)xmlData);

    // Parse and process
    DuckXmlDoc doc;
    if (doc.Parse((const char*)CFDataGetBytePtr(xmlData), [xmlData length])) {
        // YOUR PROCESSING HERE
        DuckNode* root = doc.RootNode();
        // Modify, transform, analyze...

        // Generate modified XML
        NSData* processedXML = /* your processing result */;
        xGlobals.outputXML = (CFDataRef)CFRetain((CFDataRef)processedXML);
    }
}

// Update drag to use processed version
- (NSData*)provideDragData {
    return (NSData*)xGlobals.outputXML;
}
```

The drag/drop infrastructure remains unchanged - all modifications go in `receiveXMLData:`.

## ProExtension Framework

**Apple's private framework** for professional video app extensions.

**Location:** `/System/Library/PrivateFrameworks/ProExtension.framework`

**Required linker flags:**
```
-lProExtension
-u _ProExtensionMain
```

The `-u _ProExtensionMain` flag forces inclusion of the extension entry point. Without it, the linker strips the symbol and the extension won't load.

**Usage in code:**
```objc
#if WORKFLOW_EXTENSION
    #import <ProExtension/ProExtension.h>
    #import <ProExtensionHost/ProExtensionHost.h>
#endif
```

Weakly linked so standalone app can build without them.

## Common Issues

### Build Errors

**"ProExtension/ProExtension.h file not found"**
- Add `/System/Library/PrivateFrameworks` to Framework Search Paths
- Extension target only

**"Undefined symbols: _ProExtensionMain"**
- Add `-u _ProExtensionMain` to Other Linker Flags
- Extension target only

**"main.cpp: undefined reference"**
- Verify `main.cpp` is in WEScaffold target only
- Must be excluded from WEScaffoldWE target

### Runtime Errors

**Extension doesn't appear in FCP**
- Check `Info.plist` has `NSExtensionPointIdentifier = com.apple.FinalCut.WorkflowExtension`
- Verify sandboxing enabled in entitlements
- Check Console.app for FCP errors: "rejecting; Ignoring mis-configured plugin"

**Drop doesn't work**
- Verify `registerForDraggedTypes:` called in `awakeFromNib`
- Check logs for `[DROP]` messages showing type validation
- Ensure XIB outlet `dropButton` is connected

**Drag back fails**
- Verify data exists: check `xGlobals.hasData`
- Ensure `provideDragData` returns non-nil
- Check logs for `[DRAG]` promise fulfillment messages

## Documentation

Comprehensive documentation included:

- **XCODE_SETUP_GUIDE.md** - Step-by-step Xcode project creation (450+ lines)
- **ARCHITECTURE.md** - Deep technical dive into extension lifecycle (730+ lines)
- **LOGGING.md** - Complete logging guide and log interpretation
- **README.md** - Quick start and overview

**Total:** ~1,500 lines of educational documentation

## Related Projects in Parent Repository

WEScaffold is part of the AutomaticDuckII suite. See parent `CLAUDE.md` at `~/AutomaticDuckII/CLAUDE.md` for:

- Building shared libraries (`duckShareARMLib`)
- Other FCPX applications (XsendMotion, XMCamFlattener, etc.)
- Shared code architecture (xml/, files/, str/, dialogs/)
- Xcode configuration files (`ADCommonIIARM.xcconfig`)
