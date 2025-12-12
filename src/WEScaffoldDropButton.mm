/******************************************************************************
 * WEScaffoldDropButton.mm
 *
 * PURPOSE:
 *   Implementation of the drop zone that receives FCPXML from Final Cut Pro.
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import "WEScaffoldDropButton.h"
#import "WEScaffoldController.h"
#import "WEScaffoldGlobals.h"

@implementation WEScaffoldDropButton

/******************************************************************************
 * awakeFromNib
 *
 * WHEN CALLED:
 *   After this object is loaded from the XIB file and all outlets are connected.
 *
 * PURPOSE:
 *   One-time initialization: register for drag types we can accept.
 *
 * EDUCATIONAL NOTE:
 *   We MUST call registerForDraggedTypes: to tell the system what pasteboard
 *   types we can handle. Without this, draggingEntered: will never be called.
 *
 *   We register for:
 *   - FCP_XML_PBOARD_TYPE: FCPXML data from FCP
 *   - NSPasteboardTypeFileURL: File drops (for testing with .fcpxml files)
 ******************************************************************************/
- (void)awakeFromNib
{
    DROP_LOG("Drop button awakening from NIB");

    //
    // Register for drag types
    // EDUCATIONAL: This tells macOS "call our draggingEntered: method when
    // someone drags one of these types over us"
    //
    [self registerForDraggedTypes:@[
        FCP_XML_PBOARD_TYPE,         // Primary: FCPXML from FCP
        NSPasteboardTypeFileURL      // Secondary: File drops for testing
    ]];

    DROP_LOG("  └─ Registered for drag types:");
    DROP_LOG("     - %@", FCP_XML_PBOARD_TYPE);
    DROP_LOG("     - NSPasteboardTypeFileURL");

    //
    // Load images for visual states
    // EDUCATIONAL: These images are in the Resources folder
    // Will be created as simple PNGs in a later step
    //
    dropInstructionsImage = [NSImage imageNamed:@"DropInstructions"];
    dropHoverImage = [NSImage imageNamed:@"DropHover"];

    if (dropInstructionsImage) {
        [self setImage:dropInstructionsImage];
        DROP_LOG("  └─ Loaded drop instructions image");
    } else {
        DROP_LOG("  └─ Warning: DropInstructions image not found");
    }

    DROP_LOG("Drop button ready to accept drops");
}

#pragma mark - NSDraggingDestination Protocol

/******************************************************************************
 * draggingEntered:
 *
 * WHEN CALLED:
 *   When user drags something over our drop zone button. This happens
 *   continuously as the mouse moves, so keep this method fast.
 *
 * PURPOSE:
 *   Validate that the dragged item is FCPXML we can accept. This determines
 *   whether the user sees a "+" cursor (we accept) or prohibited symbol
 *   (we reject).
 *
 * PARAMETERS:
 *   sender (id<NSDraggingInfo>) - Contains:
 *     - draggingPasteboard: The pasteboard with data being dragged
 *     - draggingLocation: Mouse position in our coordinate system
 *     - draggingSequenceNumber: Unique ID for this drag session
 *
 * RETURNS:
 *   NSDragOperationCopy - We accept the drop (shows "+" cursor)
 *   NSDragOperationNone - We reject the drop (shows prohibited symbol)
 *
 * IMPLEMENTATION NOTES:
 *   - Check pasteboard for "com.apple.finalcutpro.xml" type (preferred)
 *   - Could also check for file types (*.fcpxml) for file drops
 *   - Update UI to show hover state when we accept
 *   - This is called continuously, so don't do expensive operations here
 *   - The actual data isn't available yet - just checking types
 *
 * EDUCATIONAL NOTE:
 *   The pasteboard may have MULTIPLE representations of the same data:
 *     - "com.apple.finalcutpro.xml" (most recent FCPXML version)
 *     - "com.apple.finalcutpro.xml.v1-11" (specific version)
 *     - "public.file-url" (if dragging a file)
 *   We check for the generic type and let FCP provide the most recent
 *   version it supports. This makes our extension forward-compatible.
 ******************************************************************************/
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    DROP_LOG("─────── draggingEntered called ───────");
    DROP_LOG("This method validates whether we can accept the dragged item");

    //
    // Get the pasteboard from the drag session
    // EDUCATIONAL: The pasteboard is a shared data container that can hold
    // multiple representations of the same data (like FCPXML and a file path)
    //
    NSPasteboard* pboard = [sender draggingPasteboard];

    //
    // Log what types are available (educational - helps understand FCP's drag)
    //
    DROP_LOG("Available pasteboard types:");
    for (NSPasteboardType type in pboard.types) {
        DROP_LOG("  - %@", type);
    }

    //
    // Check for FCPXML pasteboard type (preferred method for WE)
    // EDUCATIONAL: This is the standard way to receive FCPXML from FCP
    // The .xml extension means "give me the most recent version you support"
    //
    if ([pboard.types containsObject:FCP_XML_PBOARD_TYPE])
    {
        DROP_LOG("✓ Found FCPXML pasteboard type - we can accept this drop");
        DROP_LOG("  Returning NSDragOperationCopy (user will see + cursor)");

        // Update UI to show we're ready to receive
        // This provides visual feedback that the drop is valid
        [self showHoverState:YES];

        return NSDragOperationCopy;
    }

    //
    // Check for file URL (for testing with .fcpxml files)
    // EDUCATIONAL: This allows developers to test by dragging files from Finder
    //
    if ([pboard.types containsObject:NSPasteboardTypeFileURL])
    {
        NSURL* fileURL = [NSURL URLFromPasteboard:pboard];
        if (fileURL && [[fileURL pathExtension] isEqualToString:@"fcpxml"]) {
            DROP_LOG("✓ Found .fcpxml file - accepting for testing");
            [self showHoverState:YES];
            return NSDragOperationCopy;
        }
    }

    //
    // No compatible type found
    //
    DROP_LOG("✗ No compatible pasteboard type - rejecting drop");
    DROP_LOG("  Returning NSDragOperationNone (user will see prohibited cursor)");

    return NSDragOperationNone;
}

/******************************************************************************
 * draggingUpdated:
 *
 * WHEN CALLED:
 *   Continuously while the mouse is over our drop zone.
 *
 * PURPOSE:
 *   Continue validating the drag. Same logic as draggingEntered:.
 *
 * EDUCATIONAL NOTE:
 *   This is called many times per second. We must return the same operation
 *   to keep the cursor consistent. If we return NSDragOperationNone, the
 *   cursor changes to prohibited even though we accepted in draggingEntered:.
 ******************************************************************************/
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    // Same validation as draggingEntered:
    NSPasteboard* pboard = [sender draggingPasteboard];

    if ([pboard.types containsObject:FCP_XML_PBOARD_TYPE]) {
        return NSDragOperationCopy;
    }

    if ([pboard.types containsObject:NSPasteboardTypeFileURL]) {
        NSURL* fileURL = [NSURL URLFromPasteboard:pboard];
        if (fileURL && [[fileURL pathExtension] isEqualToString:@"fcpxml"]) {
            return NSDragOperationCopy;
        }
    }

    return NSDragOperationNone;
}

/******************************************************************************
 * draggingExited:
 *
 * WHEN CALLED:
 *   When the mouse leaves our drop zone without dropping.
 *
 * PURPOSE:
 *   Reset UI to non-hover state.
 ******************************************************************************/
- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    DROP_LOG("draggingExited: mouse left without dropping");
    [self showHoverState:NO];
}

/******************************************************************************
 * prepareForDragOperation:
 *
 * WHEN CALLED:
 *   Just before performDragOperation:, when the user releases the mouse.
 *
 * PURPOSE:
 *   Final chance to reject the drop. We always return YES.
 *
 * EDUCATIONAL NOTE:
 *   This is where you'd do any final validation before accepting the drop.
 *   For the scaffold, we've already validated in draggingEntered:, so we
 *   just return YES to proceed to performDragOperation:.
 ******************************************************************************/
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    DROP_LOG("prepareForDragOperation: user released mouse - drop accepted");
    DROP_LOG("  Returning YES - will proceed to performDragOperation:");
    return YES;
}

/******************************************************************************
 * performDragOperation:
 *
 * WHEN CALLED:
 *   After user releases mouse and prepareForDragOperation: returns YES.
 *
 * PURPOSE:
 *   Extract the FCPXML data from the pasteboard and store it for processing.
 *   This is THE critical method - where data actually transfers from FCP to us.
 *
 * PARAMETERS:
 *   sender - Contains draggingPasteboard with the data
 *
 * RETURNS:
 *   YES if we successfully extracted and stored the data
 *   NO if something went wrong
 *
 * EDUCATIONAL NOTE:
 *   This method extracts NSData from the pasteboard using dataForType:.
 *   The data is complete FCPXML - not a promise, not a reference, the full XML.
 *
 *   We then pass it to the controller which stores it in xGlobals for later
 *   drag back to FCP.
 ******************************************************************************/
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    DROP_LOG("══════════════════════════════════════");
    DROP_LOG("performDragOperation: called");
    DROP_LOG("This is where we actually extract the XML data");

    NSPasteboard* pboard = [sender draggingPasteboard];
    BOOL success = NO;

    //
    // Try to get FCPXML data directly from pasteboard (preferred)
    // EDUCATIONAL: This is the most common case when dragging from FCP
    //
    if ([pboard.types containsObject:FCP_XML_PBOARD_TYPE])
    {
        DROP_LOG("Extracting FCPXML from pasteboard type: %@", FCP_XML_PBOARD_TYPE);

        NSData* xmlData = [pboard dataForType:FCP_XML_PBOARD_TYPE];

        if (xmlData) {
            DROP_LOG("  ✓ Successfully extracted XML data");
            DROP_LOG("  └─ Data size: %ld bytes", [xmlData length]);

            // Pass to controller for storage
            [controller receiveXMLData:xmlData];

            success = YES;
        } else {
            ERROR_LOG("  ✗ dataForType: returned nil!");
        }
    }
    //
    // Try to load from file URL (testing fallback)
    // EDUCATIONAL: Allows testing by dragging .fcpxml files from Finder
    //
    else if ([pboard.types containsObject:NSPasteboardTypeFileURL])
    {
        NSURL* fileURL = [NSURL URLFromPasteboard:pboard];

        if (fileURL && [[fileURL pathExtension] isEqualToString:@"fcpxml"]) {
            DROP_LOG("Loading FCPXML from file: %@", [fileURL path]);

            NSError* error = nil;
            NSData* xmlData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];

            if (xmlData) {
                DROP_LOG("  ✓ Successfully loaded XML from file");
                DROP_LOG("  └─ Data size: %ld bytes", [xmlData length]);

                // Pass to controller for storage
                [controller receiveXMLData:xmlData];

                success = YES;
            } else {
                ERROR_LOG("  ✗ Failed to load file: %@", error.localizedDescription);
            }
        }
    }

    //
    // Reset UI state
    //
    [self showHoverState:NO];

    if (success) {
        DROP_LOG("performDragOperation: SUCCESS - XML stored and ready");
    } else {
        DROP_LOG("performDragOperation: FAILED - no data extracted");
    }
    DROP_LOG("══════════════════════════════════════");

    return success;
}

#pragma mark - UI Helpers

/******************************************************************************
 * showHoverState:
 *
 * PURPOSE:
 *   Switch button image between instructions and hover state.
 *
 * PARAMETERS:
 *   hover - YES to show hover image, NO to show instructions
 ******************************************************************************/
- (void)showHoverState:(BOOL)hover
{
    if (hover && dropHoverImage) {
        [self setImage:dropHoverImage];
    } else if (!hover && dropInstructionsImage) {
        [self setImage:dropInstructionsImage];
    }
}

@end
