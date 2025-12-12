# WE Scaffold Logging Guide

## Overview

WE Scaffold includes comprehensive logging at every step to help developers understand exactly what's happening during Workflow Extension execution. This guide explains how to read, interpret, and use the logs effectively.

## Logging System

### Dual Output

All logs are written to **two destinations simultaneously**:

**1. Console (NSLog)**
- Real-time output
- Visible in Xcode console (during development)
- Visible in Console.app (filter for "WEScaffold")
- Visible in FCP's console (Window → Show Console)

**2. Log File (fprintf)**
- Persistent on disk
- Location: `~/Library/Logs/WEScaffold/wescaffold.log`
- Survives extension shutdown
- Good for post-mortem analysis

### Viewing Logs

**Real-Time (Console.app):**
```bash
# Open Console.app
open /System/Applications/Utilities/Console.app

# Filter for "WEScaffold" in the search box
# Or use predicate: process == "Final Cut Pro" AND message CONTAINS "WEScaffold"
```

**Log File:**
```bash
# View entire log
cat ~/Library/Logs/WEScaffold/wescaffold.log

# Tail in real-time
tail -f ~/Library/Logs/WEScaffold/wescaffold.log

# Filter by category
grep "\[DROP\]" ~/Library/Logs/WEScaffold/wescaffold.log
grep "\[DRAG\]" ~/Library/Logs/WEScaffold/wescaffold.log
grep "\[ERROR\]" ~/Library/Logs/WEScaffold/wescaffold.log
```

## Log Categories

### [LIFECYCLE] - Extension Lifecycle Events

**What:** Extension loading, view lifecycle, window management

**When:** Extension starts, shows, hides, stops

**Example:**
```
[WEScaffold] [LIFECYCLE] Initializing WEScaffold globals...
[WEScaffold] [LIFECYCLE] Log file opened: /Users/wes/Library/Logs/WEScaffold/wescaffold.log
[WEScaffold] [LIFECYCLE] Initialization complete
[WEScaffold] [LIFECYCLE] nibName called - returning: WEScaffoldWE
[WEScaffold] [LIFECYCLE] viewDidLoad called
[WEScaffold] [LIFECYCLE]   └─ View loaded from XIB
[WEScaffold] [LIFECYCLE]   └─ IBOutlets should now be connected
[WEScaffold] [LIFECYCLE] viewDidLoad complete
[WEScaffold] [LIFECYCLE] viewWillAppear called
[WEScaffold] [LIFECYCLE]   └─ Got window reference: <NSWindow:0x600001234560>
[WEScaffold] [LIFECYCLE]   └─ Window delegate installed
[WEScaffold] [LIFECYCLE] Extension fully loaded and visible to user
```

**What to Look For:**
- ✅ "viewWillAppear called" - Extension started successfully
- ✅ "Got window reference" - Window management working
- ❌ "Failed to get window reference" - Window problem
- ❌ "outlet not connected" - XIB connection missing

### [DROP] - Receiving XML from FCP

**What:** All drag-and-drop input operations

**When:** User drags from FCP onto drop zone

**Example:**
```
[WEScaffold] [DROP] ─────── draggingEntered called ───────
[WEScaffold] [DROP] This method validates whether we can accept the dragged item
[WEScaffold] [DROP] Available pasteboard types:
[WEScaffold] [DROP]   - com.apple.finalcutpro.xml
[WEScaffold] [DROP]   - com.apple.finalcutpro.xml.v1-11
[WEScaffold] [DROP]   - public.file-url
[WEScaffold] [DROP] ✓ Found FCPXML pasteboard type - we can accept this drop
[WEScaffold] [DROP]   Returning NSDragOperationCopy (user will see + cursor)
[WEScaffold] [DROP] draggingExited: mouse left without dropping
```

Or on successful drop:

```
[WEScaffold] [DROP] ══════════════════════════════════════
[WEScaffold] [DROP] performDragOperation: called
[WEScaffold] [DROP] This is where we actually extract the XML data
[WEScaffold] [DROP] Extracting FCPXML from pasteboard type: com.apple.finalcutpro.xml
[WEScaffold] [DROP]   ✓ Successfully extracted XML data
[WEScaffold] [DROP]   └─ Data size: 45621 bytes
[WEScaffold] [DROP] performDragOperation: SUCCESS - XML stored and ready
[WEScaffold] [DROP] ══════════════════════════════════════
```

**What to Look For:**
- ✅ "Available pasteboard types" shows what FCP is providing
- ✅ "Found FCPXML pasteboard type" - Valid FCPXML drag
- ✅ "Successfully extracted XML data" - Drop succeeded
- ❌ "No compatible pasteboard type" - Wrong type dragged
- ❌ "dataForType: returned nil" - Pasteboard issue

### [DATA] - XML Data Analysis

**What:** XML data storage, memory management, analysis

**When:** After drop, during storage, before drag

**Example:**
```
[WEScaffold] [DATA] ══════════════════════════════════════
[WEScaffold] [DATA] receiveXMLData: called
[WEScaffold] [DATA]   └─ Data size: 45621 bytes
[WEScaffold] [DATA]   └─ Stored XML data
[WEScaffold] [DATA]   └─ CFDataRef address: 0x600001abcd00
[WEScaffold] [DATA]   └─ Retain count: 1 (should be 1 - we own it)
[WEScaffold] [DATA]   └─ Timestamp: 2025-11-25 14:32:17
[WEScaffold] [DATA]   └─ XML preview (first 200 bytes):
[WEScaffold] [DATA]      <?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>
<fcpxml version="1.11">
<resources>
<format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s"...
[WEScaffold] [DATA] XML data successfully stored - ready for drag back
[WEScaffold] [DATA] ══════════════════════════════════════
```

**What to Look For:**
- ✅ "Stored XML data" - Data in memory
- ✅ "Retain count: 1" - Correct memory management
- ✅ XML preview shows valid FCPXML structure
- ❌ "Retain count" > 1 - Possible memory leak
- ❌ XML preview shows garbage - Corrupted data

### [DRAG] - Sending XML Back to FCP

**What:** All drag-out operations (promise pattern)

**When:** User clicks drag box and drags to FCP

**Example:**
```
[WEScaffold] [DRAG] ══════════════════════════════════════
[WEScaffold] [DRAG] mouseDown: called - user clicked drag box
[WEScaffold] [DRAG]   ✓ Have XML data to drag: 45621 bytes
[WEScaffold] [DRAG]   └─ Created NSPasteboardItem
[WEScaffold] [DRAG]   └─ Registered as data provider for: com.apple.finalcutpro.xml
[WEScaffold] [DRAG]      PROMISE MADE: Will provide data when requested
[WEScaffold] [DRAG]   └─ Created NSDraggingItem
[WEScaffold] [DRAG]   └─ Set drag image: 64x64 document icon
[WEScaffold] [DRAG]   └─ Drag session started!
[WEScaffold] [DRAG]      User can now drag to FCP
[WEScaffold] [DRAG]      provideDataForType: will be called if FCP accepts the drop
[WEScaffold] [DRAG] ══════════════════════════════════════

[WEScaffold] [DRAG] draggingSession:sourceOperationMaskForDraggingContext:
[WEScaffold] [DRAG]   └─ Context: Outside (dragging to FCP)
[WEScaffold] [DRAG]   └─ Returning: NSDragOperationCopy

[WEScaffold] [DRAG] ══════════════════════════════════════
[WEScaffold] [DRAG] pasteboard:item:provideDataForType: called
[WEScaffold] [DRAG] THE PROMISE IS BEING FULFILLED!
[WEScaffold] [DRAG]   └─ FCP is requesting the XML data we promised
[WEScaffold] [DRAG]   └─ Type requested: com.apple.finalcutpro.xml
[WEScaffold] [DRAG]   ✓ Type matches expectation
[WEScaffold] [DRAG]   ✓ Got XML data from controller
[WEScaffold] [DRAG]   └─ Size: 45621 bytes
[WEScaffold] [DRAG]   └─ Address: 0x600001abcd00
[WEScaffold] [DRAG]   ✓ Data provided to pasteboard item
[WEScaffold] [DRAG]   └─ FCP now has the FCPXML
[WEScaffold] [DRAG]   └─ Promise fulfilled successfully!
[WEScaffold] [DRAG] ══════════════════════════════════════

[WEScaffold] [DRAG] ══════════════════════════════════════
[WEScaffold] [DRAG] draggingSession:endedAtPoint:operation:
[WEScaffold] [DRAG]   └─ Drag ended at screen point: (1234, 567)
[WEScaffold] [DRAG]   ✓ Drag SUCCEEDED
[WEScaffold] [DRAG]     Operation: Copy (FCP accepted the XML)
[WEScaffold] [DRAG]     provideDataForType: was called to transfer data
[WEScaffold] [DRAG] ══════════════════════════════════════
```

**What to Look For:**
- ✅ "PROMISE MADE" - Drag initiated correctly
- ✅ "THE PROMISE IS BEING FULFILLED!" - FCP accepted drop
- ✅ "Drag SUCCEEDED" - Complete success
- ❌ "No XML data available to drag!" - Forgot to drop first
- ❌ "Drag FAILED or CANCELLED" - Drop rejected or user cancelled

### [ERROR] - Problems Encountered

**What:** All error conditions

**When:** Something goes wrong

**Example:**
```
[WEScaffold] [ERROR] dropButton outlet not connected!
[WEScaffold] [ERROR]   ✗ No XML data available to drag!
[WEScaffold] [ERROR]     User must drop XML first before dragging back
[WEScaffold] [ERROR]   ✗ Drag FAILED or CANCELLED
[WEScaffold] [ERROR]     Possible reasons:
[WEScaffold] [ERROR]     - Dropped on invalid target
[WEScaffold] [ERROR]     - User pressed ESC
[WEScaffold] [ERROR]     - FCP rejected the drop
```

**What to Look For:**
- ❌ "outlet not connected" - XIB problem
- ❌ "No XML data available" - Workflow problem
- ❌ "Failed to open log file" - Permissions issue

## Complete Roundtrip Example

Here's what a successful complete roundtrip looks like in the logs:

### 1. Extension Starts

```
[LIFECYCLE] ===========================================
[LIFECYCLE] WEScaffold Standalone App Starting
[LIFECYCLE] ===========================================
[LIFECYCLE] Initializing WEScaffold globals...
[LIFECYCLE] Log file opened: /Users/wes/Library/Logs/WEScaffold/wescaffold.log
[LIFECYCLE] Initialization complete
[LIFECYCLE] nibName called - returning: WEScaffoldWE
[LIFECYCLE] viewDidLoad called
[LIFECYCLE] viewWillAppear called
[LIFECYCLE]   └─ Got window reference: <NSWindow:0x600001234560>
[LIFECYCLE] Extension fully loaded and visible to user
```

### 2. User Drags Project from FCP

```
[DROP] Drop button awakening from NIB
[DROP]   └─ Registered for drag types:
[DROP]      - com.apple.finalcutpro.xml
[DROP]      - NSPasteboardTypeFileURL
[DROP] Drop button ready to accept drops

[DROP] ─────── draggingEntered called ───────
[DROP] Available pasteboard types:
[DROP]   - com.apple.finalcutpro.xml
[DROP]   - com.apple.finalcutpro.xml.v1-11
[DROP] ✓ Found FCPXML pasteboard type - we can accept this drop
```

### 3. User Drops

```
[DROP] ══════════════════════════════════════
[DROP] performDragOperation: called
[DROP] Extracting FCPXML from pasteboard type: com.apple.finalcutpro.xml
[DROP]   ✓ Successfully extracted XML data
[DROP]   └─ Data size: 45621 bytes

[DATA] ══════════════════════════════════════
[DATA] receiveXMLData: called
[DATA]   └─ Stored XML data
[DATA]   └─ CFDataRef address: 0x600001abcd00
[DATA]   └─ Timestamp: 2025-11-25 14:32:17
[DATA]   └─ XML preview (first 200 bytes):
[DATA]      <?xml version="1.0" encoding="UTF-8"?>...
[DATA] XML data successfully stored - ready for drag back
[DATA] ══════════════════════════════════════
```

### 4. User Drags Back to FCP

```
[DRAG] ══════════════════════════════════════
[DRAG] mouseDown: called - user clicked drag box
[DRAG]   ✓ Have XML data to drag: 45621 bytes
[DRAG]   └─ Registered as data provider for: com.apple.finalcutpro.xml
[DRAG]      PROMISE MADE: Will provide data when requested
[DRAG]   └─ Drag session started!
[DRAG] ══════════════════════════════════════

[DRAG] ══════════════════════════════════════
[DRAG] pasteboard:item:provideDataForType: called
[DRAG] THE PROMISE IS BEING FULFILLED!
[DRAG]   ✓ Data provided to pasteboard item
[DRAG]   └─ Promise fulfilled successfully!
[DRAG] ══════════════════════════════════════

[DRAG] ══════════════════════════════════════
[DRAG] draggingSession:endedAtPoint:operation:
[DRAG]   ✓ Drag SUCCEEDED
[DRAG] ══════════════════════════════════════
```

### 5. User Closes Extension

```
[LIFECYCLE] viewWillDisappear called - extension closing
[LIFECYCLE] Cleaning up WEScaffold globals...
[DATA] Releasing xmlData (was 45621 bytes)
[LIFECYCLE] Cleanup complete
```

**Total:** ~40 log entries for one complete roundtrip!

## Troubleshooting with Logs

### Problem: Extension Doesn't Appear in FCP

**Check Logs For:**
```bash
grep "\[LIFECYCLE\]" ~/Library/Logs/WEScaffold/wescaffold.log
```

**If No Logs:**
- Extension isn't loading at all
- Check Info.plist has correct `NSExtensionPointIdentifier`
- Check extension is sandboxed (entitlements)
- Check FCP console (Window → Show Console) for system errors

**If Logs Show:**
```
[ERROR] Failed to get window reference!
```
→ Window management problem in `viewWillAppear`

### Problem: Drop Doesn't Work

**Check Logs For:**
```bash
grep "\[DROP\]" ~/Library/Logs/WEScaffold/wescaffold.log | tail -20
```

**If You See:**
```
[DROP] ✗ No compatible pasteboard type - rejecting drop
[DROP] Available pasteboard types:
[DROP]   - some.other.type
```
→ You're dragging something that isn't FCPXML

**If You See:**
```
[DROP] Drop button awakening from NIB
[DROP]   └─ Registered for drag types:
```
But no "draggingEntered" logs when dragging:
→ Drop zone not receiving drags - check XIB connections

### Problem: Drag Back Fails

**Check Logs For:**
```bash
grep "\[DRAG\]" ~/Library/Logs/WEScaffold/wescaffold.log | tail -20
```

**If You See:**
```
[ERROR]   ✗ No XML data available to drag!
```
→ Must drop XML first before dragging back

**If You See:**
```
[DRAG] mouseDown: called
[DRAG]   ✓ Have XML data to drag: 45621 bytes
[DRAG]   └─ Drag session started!
```
But no "provideDataForType" log:
→ FCP rejected the drag or user cancelled

**If You See:**
```
[DRAG]   ✗ Drag FAILED or CANCELLED
```
→ Drop target (FCP timeline) rejected the drop
   - Check you're dropping on a valid target (timeline, not browser)
   - Check FCP is in correct state to accept drops

### Problem: Memory Leak

**Check Logs For:**
```bash
grep "Retain count" ~/Library/Logs/WEScaffold/wescaffold.log
```

**Healthy:**
```
[DATA]   └─ Retain count: 1 (should be 1 - we own it)
```

**Problem:**
```
[DATA]   └─ Retain count: 3 (should be 1 - we own it)
```
→ Something else is retaining the data
   - Check for extra CFRetain calls
   - Check for missing CFRelease calls

### Problem: XML Corruption

**Check Logs For:**
```bash
grep "XML preview" ~/Library/Logs/WEScaffold/wescaffold.log
```

**Healthy:**
```
[DATA]   └─ XML preview (first 200 bytes):
[DATA]      <?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>
<fcpxml version="1.11">
```

**Problem:**
```
[DATA]   └─ XML preview (first 200 bytes):
[DATA]      ��q�X"�...garbage...
```
→ Data corrupted during transfer
   - Check memory management
   - Check CFDataRef isn't released prematurely

## Log File Rotation

The log file is overwritten each time the extension starts:

```objc
xGlobals.syslog = fopen(logPathCStr, "w");  // "w" = write (overwrite)
```

**To Keep Logs:**

Change to append mode:
```objc
xGlobals.syslog = fopen(logPathCStr, "a");  // "a" = append
```

Or manually backup before each test:
```bash
cp ~/Library/Logs/WEScaffold/wescaffold.log \
   ~/Library/Logs/WEScaffold/wescaffold-$(date +%Y%m%d-%H%M%S).log
```

## Performance Logging

The logs can help identify performance issues:

**Timestamps:**

Add timestamp to SCAFFOLD_LOG macro:
```objc
#define SCAFFOLD_LOG(fmt, ...) \
    do { \
        NSString* timestamp = [NSDateFormatter \
            localizedStringFromDate:[NSDate date] \
            dateStyle:NSDateFormatterNoStyle \
            timeStyle:NSDateFormatterMediumStyle]; \
        NSLog(@"[%@] [WEScaffold] " fmt, timestamp, ##__VA_ARGS__); \
    } while(0)
```

**Measuring Operations:**

```objc
NSDate* start = [NSDate date];
// ... operation ...
NSTimeInterval elapsed = -[start timeIntervalSinceNow];
DATA_LOG("Operation took: %.3f seconds", elapsed);
```

## Using Logs for Development

### During Development

**Terminal Window 1:** Tail log in real-time
```bash
tail -f ~/Library/Logs/WEScaffold/wescaffold.log
```

**Terminal Window 2:** Filter for errors
```bash
tail -f ~/Library/Logs/WEScaffold/wescaffold.log | grep ERROR
```

**Terminal Window 3:** Filter for specific category
```bash
tail -f ~/Library/Logs/WEScaffold/wescaffold.log | grep "\[DRAG\]"
```

### For Bug Reports

When filing a bug report, include:

1. **Full log file:**
   ```bash
   cat ~/Library/Logs/WEScaffold/wescaffold.log
   ```

2. **System console for FCP:**
   ```bash
   log show --predicate 'process == "Final Cut Pro"' --last 5m > fcp.log
   ```

3. **Steps to reproduce** with expected vs. actual log output

## Summary

The WE Scaffold logging system provides:

- ✅ **Comprehensive coverage** - Logs at every important step
- ✅ **Clear categories** - Easy to filter and understand
- ✅ **Dual output** - Console and file for flexibility
- ✅ **Educational format** - Explains what's happening and why
- ✅ **Troubleshooting friendly** - Designed to help diagnose issues

Use the logs to:
- Understand extension execution flow
- Debug drag/drop issues
- Verify correct memory management
- Learn how Workflow Extensions work
- Diagnose performance problems

The logs are your best friend when developing Workflow Extensions!
