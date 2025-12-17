# WE Scaffold

**A Complete Template for Final Cut Pro Workflow Extensions**

WE Scaffold is an educational template demonstrating the complete bidirectional drag-and-drop pattern needed for FCPXML-based Workflow Extensions. It receives FCPXML from Final Cut Pro and sends it back unchanged - providing a clean foundation for building your own processing logic.

## Features

- **Bidirectional XML Transfer** - Complete drop-in/drag-out pattern for FCPXML
- **Promise Pattern** - Efficient handling of large XML files (100MB+)
- **Dual-Mode Architecture** - Standalone app + embedded Workflow Extension
- **Extensive Logging** - 150+ log statements showing every operation
- **Educational Comments** - 60% comment ratio explaining WHY, not just WHAT
- **Production-Ready** - Based on Automatic Duck's professional extensions

## Requirements

- macOS 14.0+
- Xcode 14+ with Command Line Tools
- Final Cut Pro (for testing the extension)
- [AutomaticDuckII](https://github.com/automaticduck/AutomaticDuckII) repository at `~/AutomaticDuckII` (for shared headers)

## Quick Start

### Build

```bash
# Clone the repository
git clone https://github.com/wesplate/WEScaffold.git
cd WEScaffold

# Build using the build script
./scripts/build.sh

# Or open in Xcode
open mac/WEScaffold.xcodeproj
```

### Test in Final Cut Pro

1. Build the project
2. Launch Final Cut Pro
3. Go to **Window → Extensions → WE Scaffold**
4. Drag a project/event/clip from FCP's browser onto the drop zone
5. Drag from the extension back to FCP's timeline
6. Verify the XML is unchanged

### View Logs

```bash
# Real-time file logs
tail -f ~/Library/Logs/WEScaffold/wescaffold.log

# Or use Console.app and filter for "WEScaffold"
```

## Architecture

```
Final Cut Pro
    │
    │ (1) User drags project/event/clip
    ↓
┌─────────────────────────────────────────┐
│  WEScaffold Extension                   │
│  ┌───────────────────────────────────┐  │
│  │  Drop Zone (WEScaffoldDropButton) │  │
│  │  • NSDraggingDestination          │  │
│  │  • Validates pasteboard type      │  │
│  │  • Extracts FCPXML data           │  │
│  └─────────────┬─────────────────────┘  │
│                ↓                         │
│  ┌───────────────────────────────────┐  │
│  │  Global State (xGlobals.xmlData)  │  │
│  │  • CFDataRef storage              │  │
│  │  • Explicit retain/release        │  │
│  └─────────────┬─────────────────────┘  │
│                ↓                         │
│  ┌───────────────────────────────────┐  │
│  │  Drag Source (WEScaffoldDragBox)  │  │
│  │  • NSDraggingSource               │  │
│  │  • Promise pattern                │  │
│  │  • Lazy data provision            │  │
│  └─────────────┬─────────────────────┘  │
└────────────────┼────────────────────────┘
                 │
                 │ (2) User drags back to FCP
                 ↓
          Final Cut Pro Timeline
```

## Project Structure

```
WEScaffold/
├── mac/                          # Xcode project & configuration
│   ├── WEScaffold.xcodeproj/     # Dual-target Xcode project
│   ├── Info.plist                # App metadata
│   ├── WEScaffold.entitlements   # App sandbox settings
│   ├── WEScaffoldWE.entitlements # Extension sandbox settings
│   └── WEScaffoldWE/
│       └── Info.plist            # Extension metadata
├── src/                          # Source code (Objective-C++)
│   ├── main.mm                   # App entry point
│   ├── WEScaffoldGlobals.h/mm    # Global state + logging
│   ├── WEScaffoldController.h/mm # Main view controller
│   ├── WEScaffoldDropButton.h/mm # Drop zone implementation
│   ├── WEScaffoldDragBox.h/mm    # Drag source implementation
│   └── WEScaffoldWindowDelegate.h/mm
├── rsrc/Base.lproj/              # Interface Builder files
│   ├── WEScaffold.xib            # Standalone app UI
│   └── WEScaffoldWE.xib          # Extension UI
├── scripts/                      # Build & test helpers
│   ├── build.sh                  # Automated build
│   ├── validate_build.sh         # Pre-build validation
│   └── test_extension.sh         # FCP testing helper
└── doc/                          # Documentation
    ├── README.md                 # Technical guide
    ├── ARCHITECTURE.md           # Deep dive
    └── LOGGING.md                # Log interpretation
```

## Using as a Template

The scaffold passes XML through unchanged. To add your own processing:

**1. Modify `WEScaffoldController.mm` → `receiveXMLData:`**

```objc
- (void)receiveXMLData:(NSData*)xmlData {
    // Store original
    xGlobals.inputXML = (CFDataRef)CFRetain((__bridge CFDataRef)xmlData);

    // YOUR PROCESSING HERE
    DuckXmlDoc doc;
    if (doc.Parse((const char*)[xmlData bytes], [xmlData length])) {
        DuckNode* root = doc.RootNode();
        // Modify, transform, analyze...

        NSData* processedXML = /* your result */;
        xGlobals.outputXML = (CFDataRef)CFRetain((__bridge CFDataRef)processedXML);
    }
}
```

**2. Update `provideDragData` to return your processed XML**

The drag/drop infrastructure stays the same - just add your logic in between!

## Key Concepts Demonstrated

### Promise Pattern
Data isn't copied until the drop target requests it - critical for 100MB+ FCPXML files:

```objc
// mouseDown: registers as data provider (promise)
[pbItem setDataProvider:self forTypes:@[FCP_XML_PBOARD_TYPE]];

// provideDataForType: called only when FCP accepts the drop
- (void)pasteboard:(NSPasteboard*)pb item:(NSPasteboardItem*)item
    provideDataForType:(NSPasteboardType)type {
    [item setData:[controller provideDragData] forType:type];
}
```

### Dual-Mode Compilation
Same source builds both app and extension:

```objc
#if WORKFLOW_EXTENSION
    // Extension code (runs in FCP's process)
    - (NSString*)nibName { return @"WEScaffoldWE"; }
#else
    // Standalone app code
    int main(int argc, char* argv[]) {
        return NSApplicationMain(argc, argv);
    }
#endif
```

### Extension Lifecycle
FCP creates the window - you just provide the view controller:

```objc
- (void)viewWillAppear {
    [super viewWillAppear];
    // NOW we can get the window reference
    myWindow = [self.view window];
}
```

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI assistant guidance for this codebase |
| [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md) | Technical deep dive into extension lifecycle |
| [doc/LOGGING.md](doc/LOGGING.md) | Log interpretation and debugging guide |
| [XCODE_SETUP_GUIDE.md](XCODE_SETUP_GUIDE.md) | Detailed Xcode configuration reference |

## Troubleshooting

**Extension doesn't appear in FCP**
- Verify `NSExtensionPointIdentifier` is `com.apple.FinalCut.WorkflowExtension`
- Check sandboxing is enabled in entitlements
- Restart Final Cut Pro after building

**Drop not accepted**
- Check logs for `[DROP]` messages
- Verify `registerForDraggedTypes:` is called
- Ensure pasteboard type `com.apple.finalcutpro.xml` is registered

**Drag back fails**
- Verify `xGlobals.hasData` is true
- Check `[DRAG]` logs for promise fulfillment
- Ensure `provideDragData` returns non-nil

## Build Targets

| Target | Type | Entry Point | Notes |
|--------|------|-------------|-------|
| WEScaffold | macOS App | `main.mm` | Container app |
| WEScaffoldWE | App Extension | `ProExtensionMain` | Embedded in app |

## Dependencies

This project requires headers from the AutomaticDuckII repository:
- `DuckXmlDoc` / `DuckNode` - FCPXML parsing
- `plog` - File logging
- `DFile` - Path handling

## License

Copyright 2025 Automatic Duck, Inc.

## Related

- [Apple: Workflow Extensions](https://developer.apple.com/documentation/professional-video-applications/workflow-extensions)
- [Apple: Drag and Drop](https://developer.apple.com/documentation/appkit/drag_and_drop)
- [FCPXML Reference](https://developer.apple.com/documentation/professional-video-applications/fcpxml-reference)
