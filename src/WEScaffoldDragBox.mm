/******************************************************************************
 * WEScaffoldDragBox.mm
 *
 * PURPOSE:
 *   Implementation of the drag source that provides FCPXML back to Final Cut Pro.
 *   Demonstrates the promise pattern for efficient large data transfer.
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import "WEScaffoldDragBox.h"
#import "WEScaffoldController.h"
#import "WEScaffoldGlobals.h"
#import "WEScaffoldDropButton.h"  // For FCP_XML_PBOARD_TYPE

@implementation WEScaffoldDragBox

/******************************************************************************
 * mouseDown:
 *
 * WHEN CALLED:
 *   When user clicks on the drag box.
 *
 * PURPOSE:
 *   Initiate a drag operation to send XML back to Final Cut Pro.
 *
 * EDUCATIONAL NOTE:
 *   This is where the magic happens! We create a "promise" to provide data
 *   instead of copying it immediately. The sequence is:
 *
 *   1. Create NSPasteboardItem (empty container)
 *   2. Register ourselves as data provider (the "promise")
 *   3. Create NSDraggingItem with visual representation
 *   4. Begin dragging session
 *   5. Later, if FCP accepts the drop, provideDataForType: is called
 *
 *   This is much more efficient than copying large XML files immediately.
 ******************************************************************************/
- (void)mouseDown:(NSEvent *)theEvent
{
    DRAG_LOG("══════════════════════════════════════");
    DRAG_LOG("mouseDown: called - user clicked drag box");

    //
    // Check if we have data to drag
    // EDUCATIONAL: Must verify data exists before starting drag
    //
    if (!xGlobals.hasData || xGlobals.xmlData == NULL) {
        ERROR_LOG("  ✗ No XML data available to drag!");
        ERROR_LOG("    User must drop XML first before dragging back");
        NSBeep();  // Audio feedback
        return;
    }

    DRAG_LOG("  ✓ Have XML data to drag: %zu bytes", xGlobals.dataSize);

    //
    // Create Pasteboard Item
    // EDUCATIONAL: NSPasteboardItem is a container for promised data.
    // At this point, it's empty - we haven't put any data in it yet.
    //
    NSPasteboardItem* pbItem = [[NSPasteboardItem alloc] init];
    DRAG_LOG("  └─ Created NSPasteboardItem");

    //
    // Register ourselves as the data provider (THE PROMISE)
    // EDUCATIONAL: This is the key to the promise pattern!
    // We're saying "I promise to provide data of type FCP_XML_PBOARD_TYPE
    // if you call my provideDataForType: method"
    //
    // The data is NOT copied yet. That happens later in provideDataForType:.
    //
    NSArray* supportedTypes = @[FCP_XML_PBOARD_TYPE];
    BOOL ok = [pbItem setDataProvider:self forTypes:supportedTypes];

    if (ok) {
        DRAG_LOG("  └─ Registered as data provider for: %@", FCP_XML_PBOARD_TYPE);
        DRAG_LOG("     PROMISE MADE: Will provide data when requested");
    } else {
        ERROR_LOG("  ✗ Failed to register as data provider!");
        return;
    }

    //
    // Create Dragging Item
    // EDUCATIONAL: NSDraggingItem wraps the pasteboard item and adds
    // visual representation (what the user sees while dragging)
    //
    NSDraggingItem* dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    DRAG_LOG("  └─ Created NSDraggingItem");

    //
    // Set visual representation
    // EDUCATIONAL: We create a simple image to show while dragging.
    // For the scaffold, we use a small icon. Real WEs might show a thumbnail.
    //
    NSImage* dragImage = [NSImage imageNamed:@"NSDocument"];
    if (!dragImage) {
        // Fallback: create a simple colored image
        dragImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
    }

    NSRect draggingRect = NSMakeRect(0, 0, 64, 64);
    [dragItem setDraggingFrame:draggingRect contents:dragImage];
    DRAG_LOG("  └─ Set drag image: 64x64 document icon");

    //
    // Begin Dragging Session
    // EDUCATIONAL: This starts the drag operation. The user can now drag
    // to FCP. If they drop on a valid target, our provideDataForType:
    // method will be called to fulfill the promise.
    //
    NSDraggingSession* draggingSession = [self beginDraggingSessionWithItems:@[dragItem]
                                                                       event:theEvent
                                                                      source:self];

    // Animation if drag fails or is cancelled
    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    draggingSession.draggingFormation = NSDraggingFormationNone;

    DRAG_LOG("  └─ Drag session started!");
    DRAG_LOG("     User can now drag to FCP");
    DRAG_LOG("     provideDataForType: will be called if FCP accepts the drop");
    DRAG_LOG("══════════════════════════════════════");
}

#pragma mark - NSDraggingSource Protocol

/******************************************************************************
 * draggingSession:sourceOperationMaskForDraggingContext:
 *
 * WHEN CALLED:
 *   During drag operation to determine what operations are allowed.
 *
 * PURPOSE:
 *   Tell the system what drag operations we support.
 *
 * PARAMETERS:
 *   context - NSDraggingContextOutsideApplication (dragging to FCP) or
 *             NSDraggingContextWithinApplication (dragging within our app)
 *
 * RETURNS:
 *   NSDragOperationCopy - We support copy operations
 *
 * EDUCATIONAL NOTE:
 *   For Workflow Extensions, we always drag to FCP (outside application).
 *   We return NSDragOperationCopy which means "create a copy" - standard
 *   for XML data transfer.
 ******************************************************************************/
- (NSDragOperation)draggingSession:(NSDraggingSession *)session
    sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    DRAG_LOG("draggingSession:sourceOperationMaskForDraggingContext:");
    DRAG_LOG("  └─ Context: %@", (context == NSDraggingContextOutsideApplication) ?
             @"Outside (dragging to FCP)" : @"Within application");
    DRAG_LOG("  └─ Returning: NSDragOperationCopy");

    // Always allow copy operation
    return NSDragOperationCopy;
}

/******************************************************************************
 * draggingSession:endedAtPoint:operation:
 *
 * WHEN CALLED:
 *   After drag operation completes (success, failure, or cancel).
 *
 * PURPOSE:
 *   Log the result and provide user feedback.
 *
 * PARAMETERS:
 *   screenPoint - Where drag ended (in screen coordinates)
 *   operation   - What happened: NSDragOperationCopy (success) or
 *                 NSDragOperationNone (failed/cancelled)
 *
 * EDUCATIONAL NOTE:
 *   This is called after provideDataForType: (if drop was accepted).
 *   If operation == NSDragOperationNone, the drag was rejected or cancelled.
 ******************************************************************************/
- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation
{
    DRAG_LOG("══════════════════════════════════════");
    DRAG_LOG("draggingSession:endedAtPoint:operation:");
    DRAG_LOG("  └─ Drag ended at screen point: (%.0f, %.0f)", screenPoint.x, screenPoint.y);

    if (operation == NSDragOperationNone) {
        //
        // Drag failed or was cancelled
        //
        ERROR_LOG("  ✗ Drag FAILED or CANCELLED");
        ERROR_LOG("    Possible reasons:");
        ERROR_LOG("    - Dropped on invalid target");
        ERROR_LOG("    - User pressed ESC");
        ERROR_LOG("    - FCP rejected the drop");

        NSBeep();  // Audio feedback for failure
    }
    else if (operation == NSDragOperationCopy) {
        //
        // Drag succeeded!
        //
        DRAG_LOG("  ✓ Drag SUCCEEDED");
        DRAG_LOG("    Operation: Copy (FCP accepted the XML)");
        DRAG_LOG("    provideDataForType: was called to transfer data");
    }

    DRAG_LOG("══════════════════════════════════════");
}

#pragma mark - NSPasteboardItemDataProvider Protocol

/******************************************************************************
 * pasteboard:item:provideDataForType:
 *
 * WHEN CALLED:
 *   When FCP (or any drop target) actually wants the data we promised.
 *   This is the "promise fulfillment" moment!
 *
 * PURPOSE:
 *   Provide the actual FCPXML data that we promised in mouseDown:.
 *
 * PARAMETERS:
 *   pasteboard - The pasteboard requesting data
 *   item       - The pasteboard item we created
 *   type       - The type of data requested (should be FCP_XML_PBOARD_TYPE)
 *
 * EDUCATIONAL NOTE:
 *   This is called ONLY if FCP accepts the drop. If the drag is cancelled
 *   or dropped on an invalid target, this method is never called.
 *
 *   This is the payoff of the promise pattern:
 *   - If drag fails: no data copied (efficient!)
 *   - If drag succeeds: data copied only when needed (just-in-time)
 *
 *   For large XML files (100MB+), this saves significant time and memory.
 ******************************************************************************/
- (void)pasteboard:(NSPasteboard *)pasteboard
              item:(NSPasteboardItem *)item
provideDataForType:(NSPasteboardType)type
{
    DRAG_LOG("══════════════════════════════════════");
    DRAG_LOG("pasteboard:item:provideDataForType: called");
    DRAG_LOG("THE PROMISE IS BEING FULFILLED!");
    DRAG_LOG("  └─ FCP is requesting the XML data we promised");
    DRAG_LOG("  └─ Type requested: %@", type);

    //
    // Verify the type is what we expect
    // EDUCATIONAL: Should always be FCP_XML_PBOARD_TYPE
    //
    if (![type isEqualToString:FCP_XML_PBOARD_TYPE]) {
        ERROR_LOG("  ✗ Unexpected type requested: %@", type);
        ERROR_LOG("    Expected: %@", FCP_XML_PBOARD_TYPE);
        return;
    }

    DRAG_LOG("  ✓ Type matches expectation");

    //
    // Get the data from controller
    // EDUCATIONAL: Controller retrieves from xGlobals.xmlData
    //
    NSData* xmlData = [controller provideDragData];

    if (xmlData) {
        DRAG_LOG("  ✓ Got XML data from controller");
        DRAG_LOG("  └─ Size: %ld bytes", [xmlData length]);
        DRAG_LOG("  └─ Address: %p", xmlData);

        //
        // Provide the data to the pasteboard item
        // EDUCATIONAL: This is the actual data transfer!
        // NSData is copied to the pasteboard, and FCP can now access it.
        //
        [item setData:xmlData forType:type];

        DRAG_LOG("  ✓ Data provided to pasteboard item");
        DRAG_LOG("  └─ FCP now has the FCPXML");
        DRAG_LOG("  └─ Promise fulfilled successfully!");
    }
    else {
        ERROR_LOG("  ✗ Controller returned nil data!");
        ERROR_LOG("    This should never happen - data was validated in mouseDown:");
    }

    DRAG_LOG("══════════════════════════════════════");
}

@end
