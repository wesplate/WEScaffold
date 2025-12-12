# WE Scaffold Architecture

## Overview

WE Scaffold demonstrates the complete architecture of a Final Cut Pro Workflow Extension, from extension registration through bidirectional XML transfer. This document provides a deep technical dive into how each component works and why it's designed that way.

## Workflow Extension Lifecycle

### 1. Extension Discovery

**When:** Final Cut Pro launches

**What Happens:**
1. FCP scans `/Applications` and `~/Applications` for `.app` bundles
2. Looks inside each app's `Contents/PlugIns/` for `.appex` bundles
3. Reads each `.appex`'s Info.plist looking for:
   ```xml
   <key>NSExtensionPointIdentifier</key>
   <string>com.apple.FinalCut.WorkflowExtension</string>
   ```
4. If found, registers the extension with the system

**Key Files:**
- `WEScaffold.app/Contents/PlugIns/WEScaffoldWE.appex/Contents/Info.plist`
- Must have correct `NSExtensionPointIdentifier`
- Must specify `ProExtensionPrincipalViewControllerClass`

### 2. Extension Loading

**When:** User selects Window → Extensions → WE Scaffold

**What Happens:**
1. macOS loads the `.appex` binary into FCP's process
2. Links against `ProExtension.framework` (private Apple framework)
3. Calls `ProExtensionMain` (entry point, forced via `-u _ProExtensionMain`)
4. ProExtension framework instantiates the principal view controller
5. Loads the XIB file specified in `nibName` method

**Key Code:**
```objc
// WEScaffoldController.mm
- (NSString*)nibName {
    return @"WEScaffoldWE";  // Loads WEScaffoldWE.xib
}
```

**Why No main() Function:**
- Extensions don't have `main()` - they're loaded into FCP's process
- `ProExtensionMain` is the entry point (linked via linker flag)
- This is fundamentally different from standalone apps

### 3. View Controller Lifecycle

**Sequence:**
```
1. init / initWithCoder:       (NSViewController created)
2. nibName                     (which XIB to load?)
3. viewDidLoad                 (XIB loaded, outlets connected)
4. viewWillAppear              (about to show - GET WINDOW HERE)
5. [Extension is visible]
6. viewWillDisappear           (user closed extension)
```

**Critical: viewWillAppear**

This is where we get the window reference in Workflow Extension mode:

```objc
- (void)viewWillAppear {
    [super viewWillAppear];

    // CRITICAL: Get window reference (FCP created it)
    myWindow = [self.view window];

    // Install window delegate for resize events
    WEScaffoldWindowDelegate* delegate = [[WEScaffoldWindowDelegate alloc] init];
    delegate->controller = self;
    [myWindow setDelegate:delegate];
}
```

**Why Here and Not viewDidLoad:**
- In `viewDidLoad`, the view exists but isn't in a window yet
- FCP creates and manages the window
- Only after `viewWillAppear` can we access `self.view.window`

### 4. Extension Shutdown

**When:** User closes the extension window

**What Happens:**
1. `viewWillDisappear` is called
2. We clean up resources (release XML data, close log file)
3. Extension unloads from memory
4. FCP continues running

**Key Code:**
```objc
- (void)viewWillDisappear {
    [super viewWillDisappear];
    xGlobals.Cleanup();  // Release CFDataRef, close files
}
```

## Data Flow Architecture

### The Bidirectional Pattern

```
FCP → Drop Button → Global Storage → Drag Box → FCP
```

This is the fundamental pattern of all Workflow Extensions that transform content.

### Component Responsibilities

#### 1. Drop Button (Input Side)

**Class:** `WEScaffoldDropButton`

**Responsibilities:**
- Register for drag types (`awakeFromNib`)
- Validate dropped items (`draggingEntered:`)
- Extract NSData from pasteboard (`performDragOperation:`)
- Store in global state via controller

**Key Protocol:** `NSDraggingDestination`

**Methods Called by System:**
```
draggingEntered:     → Validate, return NSDragOperationCopy or None
draggingUpdated:     → Continue validation while hovering
draggingExited:      → User dragged away without dropping
prepareForDrag...:   → Final validation before data transfer
performDrag...:      → EXTRACT DATA HERE
```

**Critical Code:**
```objc
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard];

    // Extract FCPXML
    NSData* xmlData = [pboard dataForType:FCP_XML_PBOARD_TYPE];

    // Store via controller
    [controller receiveXMLData:xmlData];

    return YES;
}
```

#### 2. Controller (Coordinator)

**Class:** `WEScaffoldController`

**Responsibilities:**
- Manage extension lifecycle
- Coordinate between drop button and drag box
- Store data in global state
- Provide data when drag box requests it

**Not Responsible For:**
- Processing XML (that's for derived projects)
- Direct drag/drop implementation (delegated to button/box)

**Key Methods:**
```objc
- (void)receiveXMLData:(NSData*)xmlData {
    // Store in global state
    xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);
    xGlobals.hasData = true;
    // Update UI
}

- (NSData*)provideDragData {
    // Return stored data for dragging
    return (NSData*)xGlobals.xmlData;
}
```

#### 3. Drag Box (Output Side)

**Class:** `WEScaffoldDragBox`

**Responsibilities:**
- Initiate drag on mouse click (`mouseDown:`)
- Create promise for data (`setDataProvider:forTypes:`)
- Provide data when FCP requests (`pasteboard:item:provideDataForType:`)
- Report drag result

**Key Protocols:**
- `NSDraggingSource` - Initiates drags
- `NSPasteboardItemDataProvider` - Provides promised data

**The Promise Pattern:**

This is the most important pattern to understand!

**Step 1: Make the Promise (mouseDown:)**
```objc
- (void)mouseDown:(NSEvent*)theEvent {
    // Create empty pasteboard item
    NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];

    // PROMISE to provide data (doesn't copy yet!)
    [pbItem setDataProvider:self forTypes:@[FCP_XML_PBOARD_TYPE]];

    // Create dragging item
    NSDraggingItem* dragItem = [[NSDraggingItem alloc]
                                 initWithPasteboardWriter:pbItem];

    // Begin drag
    [self beginDraggingSessionWithItems:@[dragItem]
                                  event:theEvent
                                 source:self];
}
```

**Step 2: Fulfill the Promise (provideDataForType:)**
```objc
- (void)pasteboard:(NSPasteboard*)pasteboard
              item:(NSPasteboardItem*)item
provideDataForType:(NSPasteboardType)type {

    // NOW copy the data (only if FCP accepts the drop)
    NSData* xmlData = [controller provideDragData];
    [item setData:xmlData forType:type];
}
```

**Why Use Promises?**

1. **Efficiency:** Don't copy 100MB XML unless destination wants it
2. **Just-in-time:** Data copied only when actually needed
3. **Standard pattern:** All FCP Workflow Extensions use this
4. **Memory:** Saves RAM if drag is cancelled

**Timeline:**
```
User clicks drag box
  ↓
mouseDown: called
  ↓
Create NSPasteboardItem (empty)
  ↓
setDataProvider:forTypes: (PROMISE made)
  ↓
beginDraggingSession (user drags)
  ↓
User drops on FCP timeline
  ↓
pasteboard:item:provideDataForType: called (PROMISE fulfilled)
  ↓
Data transferred to FCP
```

If user cancels drag or drops on invalid target, `provideDataForType:` is **never called** - no data copied!

#### 4. Global State

**Structure:** `WEScaffoldGlobals`

**Why Global?**
- Drop button and drag box are separate objects
- They need to share data
- Simplest pattern for a scaffold

**Alternative Approaches:**
- Controller as mediator (more complex)
- Delegate pattern (overkill for scaffold)
- Notifications (async, harder to debug)

**Memory Management:**

We use `CFDataRef` instead of `NSData*`:

```objc
// Store with explicit retain
xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);

// Release when done
CFRelease(xGlobals.xmlData);
xGlobals.xmlData = NULL;
```

**Why CFDataRef?**
1. **Educational:** Explicit memory management teaches ownership
2. **C++ compatible:** Can use in C++ code without Objective-C++
3. **Clear lifetime:** You see exactly when data is allocated/freed
4. **Toll-free bridged:** `(NSData*)cfDataRef` works seamlessly

## Pasteboard Type System

### FCPXML Type Hierarchy

FCP provides multiple pasteboard types for the same data:

```
com.apple.finalcutpro.xml           ← Use this (latest version)
com.apple.finalcutpro.xml.v1-11     ← Specific version
com.apple.finalcutpro.xml.v1-10
com.apple.finalcutpro.xml.v1-9
...
public.file-url                     ← If dragging file
```

**Best Practice:** Register for `com.apple.finalcutpro.xml`

This is the "latest version" identifier - FCP automatically provides the most recent FCPXML version it supports.

**Forward Compatibility:**

When FCP 11.0 comes out with FCPXML v1.14:
- Your extension still registers for `com.apple.finalcutpro.xml`
- FCP provides v1.14 automatically
- No code changes needed!

### Validation Strategy

```objc
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard];

    // Check for generic type (preferred)
    if ([pboard.types containsObject:FCP_XML_PBOARD_TYPE]) {
        return NSDragOperationCopy;  // Accept
    }

    // Could also check for specific versions if needed
    if ([pboard.types containsObject:@"com.apple.finalcutpro.xml.v1-11"]) {
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;  // Reject
}
```

## ProExtension Framework

### What Is It?

ProExtension is Apple's **private framework** for professional video app extensions. It's not documented publicly, but it provides:

1. Extension entry point (`ProExtensionMain`)
2. Host app information (`ProExtensionHostSingleton`)
3. Communication channel with FCP

### Linking

**Linker Flags Required:**
```
-lProExtension
-u _ProExtensionMain
```

**Why `-u _ProExtensionMain`?**

The `-u` flag forces the linker to include a symbol even if it's not directly referenced. Without it, the linker might strip out `ProExtensionMain` thinking it's unused, and the extension won't load.

### Framework Search Path

```
/System/Library/PrivateFrameworks
```

This is where `ProExtension.framework` lives. It's marked "private" because it's not part of the public SDK, but it's essential for Workflow Extensions.

### Weak Linking

```objc
#if WORKFLOW_EXTENSION
    #import <ProExtension/ProExtension.h>
    #import <ProExtensionHost/ProExtensionHost.h>
#endif
```

Frameworks are weakly linked so the standalone app can build without them (they only exist when running inside FCP).

## Conditional Compilation

### The WORKFLOW_EXTENSION Macro

**Set by Build Settings:**
- WEScaffoldWE target: `WORKFLOW_EXTENSION=1`
- WEScaffold target: `WORKFLOW_EXTENSION=0` (or undefined)

**Usage:**

```objc
#if WORKFLOW_EXTENSION
    // Extension-specific code
    - (NSString*)nibName {
        return @"WEScaffoldWE";
    }
#else
    // Standalone app code
    int main(int argc, char* argv[]) {
        return NSApplicationMain(argc, argv);
    }
#endif
```

**Why Needed:**

1. **Different entry points:** App has `main()`, extension uses `ProExtensionMain`
2. **Different UI:** App uses `WEScaffold.xib`, extension uses `WEScaffoldWE.xib`
3. **Different window management:** App creates window, extension gets window from FCP
4. **Different lifecycle:** App has `NSApplicationDelegate`, extension has `NSViewController`

## Sandboxing Requirements

### Why Required?

Apple requires **all** App Extensions to be sandboxed for security. If the extension isn't sandboxed, FCP will reject it:

```
rejecting; Ignoring mis-configured plugin: plug-ins must be sandboxed
```

### Entitlements

**Minimum Required:**
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

**What They Mean:**

1. `app-sandbox` - Enable sandboxing (REQUIRED)
2. `files.user-selected.read-write` - Allow reading/writing files user explicitly chooses (via drag/drop or file picker)

### What Sandbox Restrictions Mean

**Can:**
- Access data dragged from FCP (user initiated)
- Write to `~/Library/Logs` (logging)
- Access network (if needed)
- Use system frameworks

**Cannot:**
- Access arbitrary files without user permission
- Modify system settings
- Access other apps' data
- Use deprecated/unsafe APIs

## Window Management

### In Standalone App Mode

```objc
// Traditional pattern
- (void)applicationDidFinishLaunching:(NSNotification*)note {
    // Window created from XIB, we own it
    [myWindow makeKeyAndOrderFront:nil];
}
```

### In Workflow Extension Mode

```objc
// Different pattern - FCP owns window
- (void)viewWillAppear {
    // Get window FCP created
    myWindow = [self.view window];

    // We can:
    // - Set delegate
    // - Read size
    // - Update content

    // We cannot:
    // - Close it
    // - Move it
    // - Set title (FCP controls that)
}
```

**Key Differences:**

| Aspect | Standalone App | Workflow Extension |
|--------|---------------|-------------------|
| Window creation | We create it | FCP creates it |
| Window ownership | We own it | FCP owns it |
| When available | `applicationDidFinishLaunching:` | `viewWillAppear` |
| Close control | We can close | User closes (we can't) |
| Title | We set | FCP sets |
| Resize | We control min/max | FCP controls (we respond) |

## Logging Architecture

### Dual System

**1. Console Logging (NSLog)**
```objc
NSLog(@"[WEScaffold] Message");
```

Appears in:
- Xcode console (when debugging)
- Console.app (filter for "WEScaffold")
- FCP's console (Window → Show Console)

**2. File Logging (fprintf)**
```objc
fprintf(xGlobals.syslog, "Message\n");
fflush(xGlobals.syslog);
```

Writes to:
- `~/Library/Logs/WEScaffold/wescaffold.log`

### Educational Macros

```objc
#define LIFECYCLE_LOG(fmt, ...) SCAFFOLD_LOG("[LIFECYCLE] " fmt, ##__VA_ARGS__)
#define DROP_LOG(fmt, ...)      SCAFFOLD_LOG("[DROP] " fmt, ##__VA_ARGS__)
#define DRAG_LOG(fmt, ...)      SCAFFOLD_LOG("[DRAG] " fmt, ##__VA_ARGS__)
#define DATA_LOG(fmt, ...)      SCAFFOLD_LOG("[DATA] " fmt, ##__VA_ARGS__)
#define ERROR_LOG(fmt, ...)     SCAFFOLD_LOG("[ERROR] " fmt, ##__VA_ARGS__)
```

**Categories:**
- `[LIFECYCLE]` - Extension loading, view lifecycle
- `[DROP]` - Receiving XML from FCP
- `[DRAG]` - Sending XML back to FCP
- `[DATA]` - XML data analysis
- `[ERROR]` - Problems encountered

**Why Categorize?**

1. Easy to filter logs by category
2. Understand execution flow at a glance
3. Debug specific issues (e.g., grep for `[DROP]`)
4. Educational - shows what's happening where

## Extension Points for Customization

### Where to Add Processing

**Current (Pass-Through):**
```objc
- (void)receiveXMLData:(NSData*)xmlData {
    xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);
}
```

**With Processing:**
```objc
- (void)receiveXMLData:(NSData*)xmlData {
    // Store original
    xGlobals.inputXML = (CFDataRef)CFRetain((CFDataRef)xmlData);

    // Parse with DuckXmlDoc
    DuckXmlDoc doc;
    if (doc.Parse((const char*)CFDataGetBytePtr(xmlData), [xmlData length])) {

        // YOUR PROCESSING HERE
        DuckNode* root = doc.RootNode();
        // Modify nodes, add elements, etc.

        // Generate modified XML
        NSData* modifiedXML = /* ... */;

        // Store for drag back
        xGlobals.outputXML = (CFDataRef)CFRetain((CFDataRef)modifiedXML);
    }
}
```

**Update drag to use output:**
```objc
- (NSData*)provideDragData {
    // Return processed version instead of original
    return (NSData*)xGlobals.outputXML;
}
```

### Where to Add UI

**Controller outlets:**
```objc
@interface WEScaffoldController : NSViewController {
    IBOutlet NSButton* processButton;
    IBOutlet NSProgressIndicator* progressBar;
    IBOutlet NSPopUpButton* settingsMenu;
}
```

**Add to XIB, connect outlets, implement actions**

### Where to Add Settings

Use `NSUserDefaults` for persistence:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];

    BOOL enabled = [[NSUserDefaults standardUserDefaults]
                    boolForKey:@"MyFeatureEnabled"];
}

- (IBAction)toggleFeature:(id)sender {
    [[NSUserDefaults standardUserDefaults]
        setBool:enabled forKey:@"MyFeatureEnabled"];
}
```

## Common Pitfalls

### 1. Forgetting to Register Drag Types

**Problem:** Drop doesn't work, cursor shows prohibited symbol

**Solution:**
```objc
- (void)awakeFromNib {
    [self registerForDraggedTypes:@[FCP_XML_PBOARD_TYPE]];
}
```

### 2. Getting Window Too Early

**Problem:** `myWindow` is nil

**Solution:** Get window in `viewWillAppear`, not `viewDidLoad`

### 3. Not Checking for Data

**Problem:** Crash when dragging without dropping first

**Solution:**
```objc
- (void)mouseDown:(NSEvent*)theEvent {
    if (!xGlobals.hasData) {
        NSBeep();
        return;
    }
    // ... proceed with drag
}
```

### 4. Memory Leaks with CFDataRef

**Problem:** Data not released, memory grows

**Solution:**
```objc
if (xGlobals.xmlData) {
    CFRelease(xGlobals.xmlData);  // Always release before replacing
}
xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)newData);
```

### 5. Extension Not Sandboxed

**Problem:** FCP rejects extension

**Solution:** Ensure entitlements file has:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

## Performance Considerations

### Large XML Files

FCPXML files can be **very large** (100MB+ for complex projects).

**Why Promise Pattern Matters:**

Without promises:
- `mouseDown:` would copy 100MB to pasteboard
- User drags to FCP
- If cancelled: 100MB copied for nothing
- Memory spike, UI lag

With promises:
- `mouseDown:` creates tiny promise object
- User drags to FCP
- If cancelled: nothing copied (efficient!)
- Only if dropped: `provideDataForType:` copies data

**Measurement:**
- Time to start drag: ~1ms (constant, regardless of file size)
- Time to fulfill promise: varies with file size (only if accepted)

### UI Responsiveness

**Keep draggingEntered: Fast:**

This method is called continuously while dragging. Don't do expensive operations:

```objc
// GOOD - fast type check
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard* pboard = [sender draggingPasteboard];
    if ([pboard.types containsObject:FCP_XML_PBOARD_TYPE]) {
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

// BAD - slow data parsing
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSData* data = [pboard dataForType:FCP_XML_PBOARD_TYPE];
    DuckXmlDoc doc;
    if (doc.Parse(...)) {  // ← TOO SLOW for continuous callback!
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}
```

## Summary

The WE Scaffold architecture demonstrates:

1. **Extension lifecycle** from discovery to shutdown
2. **Bidirectional data flow** (FCP → Extension → FCP)
3. **Promise pattern** for efficient large data transfer
4. **Dual-mode compilation** (app + extension from same source)
5. **Proper memory management** with CFDataRef
6. **Sandboxing** requirements and implications
7. **Logging strategy** for developer education

All architectural decisions prioritize:
- **Simplicity** - Easiest possible implementation
- **Education** - Extensive comments explaining why
- **Extensibility** - Easy to add processing logic
- **Best practices** - Patterns used by professional Workflow Extensions

The scaffold is a production-ready foundation for building any FCPXML-processing Workflow Extension.
