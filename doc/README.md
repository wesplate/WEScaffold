# WE Scaffold - Workflow Extension Template for Final Cut Pro

## What Is This?

WE Scaffold is a minimal, educational template for building Final Cut Pro X Workflow Extensions. It demonstrates the bidirectional drag-and-drop pattern that all Workflow Extensions need: receiving FCPXML from FCP and sending it back.

**Key Features:**
- ✅ Pass-through pattern: Receives XML, returns it unchanged (no processing)
- ✅ Extensive logging at every step for developer education
- ✅ Comprehensive inline comments explaining WHY, not just WHAT
- ✅ Integration with Automatic Duck shared libraries (DuckXmlDoc, plog, DFile)
- ✅ Dual-mode architecture: Standalone app + embedded Workflow Extension
- ✅ Promise pattern for efficient large XML transfer

## Why Use This?

- **Learn by example**: See exactly what happens at each step via extensive logging
- **Clean foundation**: No processing logic to distract from Workflow Extension mechanics
- **Copy and customize**: Add your own XML processing between receive and drag
- **Production-ready patterns**: Based on Automatic Duck's professional Workflow Extensions

## Quick Start

### Building

1. Open `mac/WEScaffold.xcodeproj` in Xcode
2. Select target: **WEScaffold** (builds both app and extension)
3. Build (⌘B)
4. Run (⌘R) - app launches
5. The Workflow Extension is embedded in the app bundle

### Testing in Final Cut Pro

1. Build the project
2. Launch Final Cut Pro
3. Window → Extensions → WE Scaffold
4. Create a simple project in FCP
5. Drag the project from the browser onto the WE Scaffold drop zone
6. Watch Console.app for detailed logs
7. Drag from WE Scaffold back to the FCP timeline
8. Verify the project is unchanged

### Viewing Logs

**Real-time (Console.app):**
```bash
# Open Console.app and filter for "WEScaffold"
open /System/Applications/Utilities/Console.app
```

**Log File:**
```bash
# Detailed log with all events
tail -f ~/Library/Logs/WEScaffold/wescaffold.log
```

## Architecture

```
┌──────────────────────────────────────────┐
│         Final Cut Pro                     │
│  (User drags project/event/clip)         │
└─────────────┬────────────────────────────┘
              │ Drag FCPXML
              ↓
┌──────────────────────────────────────────┐
│  WEScaffold Extension Window              │
│  ┌────────────────────────────────────┐  │
│  │  Drop Zone (WEScaffoldDropButton)  │  │
│  │  - Accepts FCPXML drop              │  │
│  │  - Validates pasteboard type        │  │
│  │  - Extracts NSData                  │  │
│  └────────────┬───────────────────────┘  │
│               ↓                           │
│  ┌────────────────────────────────────┐  │
│  │  Global State (xGlobals.xmlData)   │  │
│  │  - Stores CFDataRef                 │  │
│  │  - Retains ownership                │  │
│  └────────────┬───────────────────────┘  │
│               ↓                           │
│  ┌────────────────────────────────────┐  │
│  │  Drag Source (WEScaffoldDragBox)   │  │
│  │  - Promise pattern                  │  │
│  │  - Provides data when requested     │  │
│  └────────────┬───────────────────────┘  │
└───────────────┼───────────────────────────┘
                │ Drag FCPXML back
                ↓
┌──────────────────────────────────────────┐
│         Final Cut Pro Timeline            │
│  (Project appears unchanged)              │
└──────────────────────────────────────────┘
```

## Project Structure

```
WEScaffold/
├── mac/
│   ├── WEScaffold.xcodeproj/      # Xcode project (2 targets)
│   ├── WEScaffold.entitlements    # App sandbox settings
│   ├── WEScaffoldWE.entitlements  # Extension sandbox settings
│   ├── Info.plist                 # App metadata
│   └── WEScaffoldWE/
│       ├── Info.plist             # Extension metadata (ProExtension config)
│       └── Assets.xcassets/       # App icons
├── src/
│   ├── main.cpp                   # App entry point
│   ├── WEScaffoldGlobals.h/cpp    # Global state + logging macros
│   ├── WEScaffoldController.h/mm  # Main NSViewController
│   ├── WEScaffoldDropButton.h/mm  # Drop zone (NSDraggingDestination)
│   ├── WEScaffoldDragBox.h/mm     # Drag source (NSDraggingSource + promise)
│   └── WEScaffoldWindowDelegate.h/mm  # Window resize handling
├── rsrc/
│   ├── Base.lproj/
│   │   ├── WEScaffold.xib         # Standalone app UI
│   │   └── WEScaffoldWE.xib       # Workflow Extension UI
│   ├── DropInstructions.png       # Drop zone default image
│   ├── DropInstructions@2x.png
│   ├── DropHover.png              # Drop zone hover image
│   └── DropHover@2x.png
└── doc/
    ├── README.md                  # This file
    ├── ARCHITECTURE.md            # Technical deep dive
    └── LOGGING.md                 # Log interpretation guide
```

## Key Files to Study

### 1. WEScaffoldGlobals.h/cpp
**Purpose:** Global state management and logging infrastructure

**Key Concepts:**
- Singleton pattern for shared state
- CFDataRef for explicit memory management
- Dual logging (console + file)
- Educational logging macros (LIFECYCLE_LOG, DROP_LOG, DRAG_LOG, etc.)

### 2. WEScaffoldController.mm
**Purpose:** Main view controller managing lifecycle

**Key Concepts:**
- NSViewController (required for Workflow Extensions)
- viewWillAppear (get window reference in WE mode)
- Conditional compilation (#if WORKFLOW_EXTENSION)
- Coordination between drop button and drag box

### 3. WEScaffoldDropButton.mm
**Purpose:** Receive FCPXML from Final Cut Pro

**Key Concepts:**
- NSDraggingDestination protocol
- Pasteboard type validation
- Data extraction from pasteboard
- Visual state feedback (hover/instructions)

### 4. WEScaffoldDragBox.mm
**Purpose:** Send FCPXML back to Final Cut Pro

**Key Concepts:**
- NSDraggingSource protocol
- NSPasteboardItemDataProvider protocol
- **Promise pattern** for efficient data transfer
- mouseDown: initiates drag
- provideDataForType: fulfills promise when FCP requests data

## Understanding the Logs

### Lifecycle Flow
```
[LIFECYCLE] Initializing WEScaffold globals...
[LIFECYCLE] viewDidLoad called
[LIFECYCLE] viewWillAppear called
[LIFECYCLE]   └─ Got window reference: <NSWindow:0x...>
[LIFECYCLE]   └─ Window delegate installed
[LIFECYCLE] Extension fully loaded and visible to user
```

### Drop Operation
```
[DROP] ─────── draggingEntered called ───────
[DROP] Available pasteboard types:
[DROP]   - com.apple.finalcutpro.xml
[DROP]   - com.apple.finalcutpro.xml.v1-11
[DROP] ✓ Found FCPXML pasteboard type - we can accept this drop
[DROP] ══════════════════════════════════════
[DROP] performDragOperation: called
[DROP]   ✓ Successfully extracted XML data
[DROP]   └─ Data size: 45621 bytes
[DATA] ══════════════════════════════════════
[DATA] receiveXMLData: called
[DATA]   └─ Stored XML data
[DATA]   └─ CFDataRef address: 0x600001abcd00
[DATA]   └─ Retain count: 1
```

### Drag Operation
```
[DRAG] ══════════════════════════════════════
[DRAG] mouseDown: called - user clicked drag box
[DRAG]   ✓ Have XML data to drag: 45621 bytes
[DRAG]   └─ Registered as data provider for: com.apple.finalcutpro.xml
[DRAG]      PROMISE MADE: Will provide data when requested
[DRAG]   └─ Drag session started!
[DRAG] ══════════════════════════════════════
[DRAG] pasteboard:item:provideDataForType: called
[DRAG] THE PROMISE IS BEING FULFILLED!
[DRAG]   ✓ Data provided to pasteboard item
[DRAG]   └─ Promise fulfilled successfully!
```

## Using WEScaffold as a Template

### Adding Your Own Processing

The scaffold is a pass-through (data in = data out). To add processing:

**1. Modify `WEScaffoldController.mm` → receiveXMLData:**

```objc
- (void)receiveXMLData:(NSData*)xmlData {
    // Store original
    xGlobals.inputXML = (CFDataRef)CFRetain((CFDataRef)xmlData);

    // YOUR PROCESSING HERE
    DuckXmlDoc doc;
    if (doc.Parse((const char*)CFDataGetBytePtr(xmlData), [xmlData length])) {
        DATA_LOG("Parsing XML for processing...");

        // Example: Modify the XML
        DuckNode* root = doc.RootNode();
        // ... your modifications ...

        // Generate modified XML
        NSData* result = /* ... your processing ... */;

        // Store processed version (this gets dragged back)
        xGlobals.outputXML = (CFDataRef)CFRetain((CFDataRef)result);
    }
}
```

**2. Update `provideDragData` to return `xGlobals.outputXML` instead of `xGlobals.xmlData`**

The drag/drop infrastructure remains unchanged!

## Integration with Shared Libraries

The scaffold demonstrates integration with Automatic Duck shared libraries:

### XML Parsing (DuckXmlDoc)
```objc
DuckXmlDoc doc;
if (doc.Parse((const char*)CFDataGetBytePtr(xGlobals.xmlData),
              CFDataGetLength(xGlobals.xmlData))) {
    DATA_LOG("Valid FCPXML: root element = %s", doc.RootNode()->Name());
}
```

### File Logging (plog)
```objc
xGlobals.syslog = fopen(logPathCStr, "w");
fprintf(xGlobals.syslog, "Log message\n");
fflush(xGlobals.syslog);
```

### Path Handling (DFile)
```objc
DFile logPath;
logPath.assign("~/Library/Logs/WEScaffold/wescaffold.log", DFILEPATH_POSIX);
```

## Troubleshooting

### Extension doesn't appear in FCP

1. Check Info.plist has correct `NSExtensionPointIdentifier`:
   ```xml
   <key>NSExtensionPointIdentifier</key>
   <string>com.apple.FinalCut.WorkflowExtension</string>
   ```

2. Verify extension is sandboxed (check entitlements)

3. Check FCP console (Window → Show Console) for loading errors

4. Restart FCP after building

### Drop not accepted

1. Check logs: `tail -f ~/Library/Logs/WEScaffold/wescaffold.log`

2. Verify `registerForDraggedTypes:` was called in `awakeFromNib`

3. Check what types FCP is providing (logged in draggingEntered:)

### Drag back fails

1. Verify XML data exists: check `xGlobals.hasData`

2. Check `provideDragData` returns non-nil

3. Ensure `provideDataForType:` is called (check logs)

4. Verify FCP is the drop target

## Further Reading

- [Apple: Workflow Extensions](https://developer.apple.com/documentation/professional-video-applications/workflow-extensions)
- [Apple: Supporting Drag and Drop](https://developer.apple.com/documentation/appkit/drag_and_drop)
- ARCHITECTURE.md - Technical deep dive into WE lifecycle
- LOGGING.md - Detailed log interpretation

## License

Copyright 2025 Automatic Duck, Inc.
