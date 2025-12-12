/******************************************************************************
 * WEScaffoldController.mm
 *
 * PURPOSE:
 *   Implementation of the main controller for WE Scaffold.
 *   Manages extension lifecycle and coordinates data flow between components.
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import "WEScaffoldController.h"
#import "WEScaffoldGlobals.h"
#import "WEScaffoldWindowDelegate.h"
#import "WEScaffoldDropButton.h"
#import "WEScaffoldDragBox.h"

@implementation WEScaffoldController

#if WORKFLOW_EXTENSION

/******************************************************************************
 * nibName
 *
 * WHEN CALLED:
 *   By the system when loading the extension's view.
 *
 * PURPOSE:
 *   Tell the system which XIB file to load for the extension's UI.
 *
 * EDUCATIONAL NOTE:
 *   In Workflow Extension mode, we return "WEScaffoldWE" which corresponds
 *   to WEScaffoldWE.xib. This is the extension's UI.
 *
 *   In standalone app mode, the XIB is loaded via the app's Info.plist
 *   (NSMainNibFile key), so we don't override this method.
 ******************************************************************************/
- (NSString*)nibName
{
    LIFECYCLE_LOG("nibName called - returning: WEScaffoldWE");
    return @"WEScaffoldWE";
}

#endif // WORKFLOW_EXTENSION

/******************************************************************************
 * viewDidLoad
 *
 * WHEN CALLED:
 *   Once, after the view is loaded from the XIB file.
 *
 * PURPOSE:
 *   Perform one-time setup after UI elements are created.
 *
 * EDUCATIONAL NOTE:
 *   At this point, all IBOutlets are connected (dropButton, dragBox, etc.).
 *   This is a good place to initialize UI state.
 *
 *   In standalone app mode, viewDidLoad might not be called if using
 *   NSWindowController. The app delegate's applicationDidFinishLaunching
 *   is used instead.
 ******************************************************************************/
- (void)viewDidLoad
{
    [super viewDidLoad];

    LIFECYCLE_LOG("viewDidLoad called");
    LIFECYCLE_LOG("  └─ View loaded from XIB");
    LIFECYCLE_LOG("  └─ IBOutlets should now be connected");

    // Initialize global state if not already done
    // EDUCATIONAL: In standalone app mode, this was called from main()
    // In WE mode, we need to call it here
    #if WORKFLOW_EXTENSION
        xGlobals.Initialize();
    #endif

    // Verify IBOutlet connections
    // EDUCATIONAL: In debug builds, check that Interface Builder connected everything
    #ifdef DEBUG
        if (!dropButton) {
            ERROR_LOG("dropButton outlet not connected!");
        }
        if (!dragBox) {
            ERROR_LOG("dragBox outlet not connected!");
        }
        if (!statusLabel) {
            ERROR_LOG("statusLabel outlet not connected!");
        }
    #endif

    // Set initial UI state
    [self updateStatus:@"Ready - Drop FCPXML here"];
    [timestampLabel setStringValue:@""];

    LIFECYCLE_LOG("viewDidLoad complete");
}

/******************************************************************************
 * viewWillAppear
 *
 * WHEN CALLED:
 *   Each time the view is about to be shown (including first time).
 *
 * PURPOSE:
 *   Perform setup that needs to happen each time the extension appears.
 *   CRITICAL: This is where we get the window reference in WE mode.
 *
 * EDUCATIONAL NOTE:
 *   In Workflow Extension mode:
 *   - FCP creates and manages the window
 *   - We get a reference via self.view.window
 *   - We can't get this earlier (window doesn't exist in viewDidLoad)
 *
 *   This is the key difference from standalone apps where you create the window.
 ******************************************************************************/
- (void)viewWillAppear
{
    [super viewWillAppear];

    LIFECYCLE_LOG("viewWillAppear called");

    #if WORKFLOW_EXTENSION
        //
        // Get window reference
        // EDUCATIONAL: In WE mode, FCP creates the window. We get a reference here.
        // This window is managed by FCP - we don't own it, can't close it, etc.
        //
        myWindow = [self.view window];

        if (myWindow) {
            LIFECYCLE_LOG("  └─ Got window reference: %@", myWindow);
        } else {
            ERROR_LOG("  └─ Failed to get window reference!");
        }

        //
        // Set up window delegate for resize handling
        // EDUCATIONAL: The delegate gets called when FCP resizes our extension window
        //
        WEScaffoldWindowDelegate* myWindowDelegate = [[WEScaffoldWindowDelegate alloc] init];
        myWindowDelegate->controller = self;
        [myWindow setDelegate:myWindowDelegate];
        LIFECYCLE_LOG("  └─ Window delegate installed");

    #else
        // In standalone app mode, window is already set up by the app delegate
        LIFECYCLE_LOG("  └─ Standalone app mode - window already configured");
    #endif

    LIFECYCLE_LOG("Extension fully loaded and visible to user");
}

/******************************************************************************
 * viewWillDisappear
 *
 * WHEN CALLED:
 *   When the extension is about to close (user closed the extension window).
 *
 * PURPOSE:
 *   Clean up resources before shutdown.
 *
 * EDUCATIONAL NOTE:
 *   In WE mode, this is called when the user closes the extension.
 *   In standalone app mode, applicationWillTerminate: is used instead.
 *
 *   We clean up global state here to prevent memory leaks.
 ******************************************************************************/
- (void)viewWillDisappear
{
    [super viewWillDisappear];

    LIFECYCLE_LOG("viewWillDisappear called - extension closing");

    // Clean up global state
    xGlobals.Cleanup();

    LIFECYCLE_LOG("Extension shutdown complete");
}

#pragma mark - XML Handling

/******************************************************************************
 * receiveXMLData:
 *
 * WHEN CALLED:
 *   By the drop button after user drops FCPXML onto it.
 *
 * PURPOSE:
 *   Store the received XML data for later drag back to FCP.
 *   This is the "input" side of the pass-through pattern.
 *
 * PARAMETERS:
 *   xmlData - NSData containing FCPXML from Final Cut Pro
 *
 * EDUCATIONAL NOTE:
 *   This is where you'd add processing in a real Workflow Extension.
 *   For the scaffold, we just store the data unchanged and log extensively.
 *
 *   Key steps:
 *   1. Release any previous data (if exists)
 *   2. Retain the new data (we own it now)
 *   3. Update metadata (timestamp, size, hasData flag)
 *   4. Update UI to show data received
 *   5. Enable drag box for dragging back
 ******************************************************************************/
- (void)receiveXMLData:(NSData*)xmlData
{
    DATA_LOG("══════════════════════════════════════");
    DATA_LOG("receiveXMLData: called");
    DATA_LOG("  └─ Data size: %ld bytes", [xmlData length]);

    //
    // Release previous data if we have it
    // EDUCATIONAL: Always check for NULL before CFRelease to avoid crashes
    //
    if (xGlobals.xmlData != NULL) {
        DATA_LOG("  └─ Releasing previous XML data (%zu bytes)", xGlobals.dataSize);
        CFRelease(xGlobals.xmlData);
        xGlobals.xmlData = NULL;
    }

    //
    // Store the new data with CFRetain
    // EDUCATIONAL: We must CFRetain because the pasteboard owns the original.
    // By retaining, we ensure our copy stays valid even after the drop operation completes.
    //
    xGlobals.xmlData = (CFDataRef)CFRetain((CFDataRef)xmlData);
    xGlobals.dataSize = [xmlData length];
    xGlobals.hasData = true;

    DATA_LOG("  └─ Stored XML data");
    DATA_LOG("  └─ CFDataRef address: %p", xGlobals.xmlData);
    DATA_LOG("  └─ Retain count: %ld", CFGetRetainCount(xGlobals.xmlData));

    //
    // Store timestamp
    // EDUCATIONAL: Release old timestamp if exists, create new one
    //
    if (xGlobals.receivedTimestamp != NULL) {
        CFRelease(xGlobals.receivedTimestamp);
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    xGlobals.receivedTimestamp = (CFStringRef)CFRetain((CFStringRef)timestamp);

    DATA_LOG("  └─ Timestamp: %s", [timestamp UTF8String]);

    //
    // Update UI
    //
    [self updateStatus:[NSString stringWithFormat:@"Received: %ld bytes", xGlobals.dataSize]];
    [self updateTimestamp];

    //
    // Log first 200 bytes of XML for debugging
    // EDUCATIONAL: Shows what kind of XML we received
    //
    const char* xmlBytes = (const char*)CFDataGetBytePtr(xGlobals.xmlData);
    size_t previewLen = MIN(200, xGlobals.dataSize);
    char preview[201] = {0};
    strncpy(preview, xmlBytes, previewLen);
    DATA_LOG("  └─ XML preview (first %zu bytes):", previewLen);
    DATA_LOG("     %s...", preview);

    DATA_LOG("XML data successfully stored - ready for drag back");
    DATA_LOG("══════════════════════════════════════");
}

/******************************************************************************
 * provideDragData
 *
 * WHEN CALLED:
 *   By the drag box when user initiates a drag operation.
 *
 * PURPOSE:
 *   Return the stored XML data for dragging back to FCP.
 *   This is the "output" side of the pass-through pattern.
 *
 * RETURNS:
 *   NSData* - The FCPXML to drag back, or nil if no data available
 *
 * EDUCATIONAL NOTE:
 *   This is called BEFORE the promise pattern's provideDataForType: method.
 *   We just return a reference - the data isn't copied yet.
 *
 *   The actual data transfer happens in the drag box's provideDataForType:
 *   method when FCP requests it.
 ******************************************************************************/
- (NSData*)provideDragData
{
    DRAG_LOG("provideDragData called");

    if (!xGlobals.hasData || xGlobals.xmlData == NULL) {
        ERROR_LOG("  └─ No XML data available to drag!");
        return nil;
    }

    DRAG_LOG("  └─ Returning XML data: %zu bytes", xGlobals.dataSize);
    DRAG_LOG("  └─ CFDataRef address: %p", xGlobals.xmlData);

    // Cast CFDataRef to NSData* (they're toll-free bridged)
    // EDUCATIONAL: CFDataRef and NSData* are interchangeable via __bridge cast
    return (__bridge NSData*)xGlobals.xmlData;
}

#pragma mark - UI Updates

/******************************************************************************
 * updateStatus:
 *
 * PURPOSE:
 *   Update the status label to show current state.
 ******************************************************************************/
- (void)updateStatus:(NSString*)status
{
    if (statusLabel) {
        [statusLabel setStringValue:status];
    }
}

/******************************************************************************
 * updateTimestamp
 *
 * PURPOSE:
 *   Update the timestamp label to show when XML was received.
 ******************************************************************************/
- (void)updateTimestamp
{
    if (timestampLabel && xGlobals.receivedTimestamp) {
        NSString* ts = (__bridge NSString*)xGlobals.receivedTimestamp;
        [timestampLabel setStringValue:[NSString stringWithFormat:@"Received: %@", ts]];
    }
}

#pragma mark - Application Delegate (Standalone App Only)

#if !WORKFLOW_EXTENSION

/******************************************************************************
 * applicationDidFinishLaunching:
 *
 * WHEN CALLED:
 *   When the standalone app finishes launching.
 *
 * PURPOSE:
 *   One-time app initialization.
 *
 * EDUCATIONAL NOTE:
 *   This is only used in standalone app mode. The extension doesn't need it
 *   because viewWillAppear handles initialization.
 ******************************************************************************/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    LIFECYCLE_LOG("applicationDidFinishLaunching called (standalone app mode)");

    // Initialize global state
    xGlobals.Initialize();

    // Set initial UI state
    [self updateStatus:@"Standalone App - Use as Workflow Extension in FCP"];

    LIFECYCLE_LOG("Standalone app ready");
}

/******************************************************************************
 * applicationWillTerminate:
 *
 * WHEN CALLED:
 *   When the standalone app is about to quit.
 *
 * PURPOSE:
 *   Clean up before shutdown.
 ******************************************************************************/
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    LIFECYCLE_LOG("applicationWillTerminate called");

    // Clean up global state
    xGlobals.Cleanup();

    LIFECYCLE_LOG("App shutdown complete");
}

#endif // !WORKFLOW_EXTENSION

@end
