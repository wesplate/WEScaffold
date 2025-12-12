/******************************************************************************
 * WEScaffoldDragBox.h
 *
 * PURPOSE:
 *   Drag source box that provides FCPXML back to Final Cut Pro via drag and drop.
 *   This is the "output" side of the Workflow Extension bidirectional pattern.
 *
 * KEY CONCEPTS FOR DEVELOPERS:
 *   - NSDraggingSource protocol: How to initiate drags
 *   - NSPasteboardItemDataProvider protocol: Promise pattern for efficient data transfer
 *   - mouseDown: initiates the drag operation
 *   - Data isn't copied until FCP actually requests it (lazy evaluation)
 *
 * WORKFLOW SEQUENCE:
 *   1. User clicks on the drag box (mouseDown: called)
 *   2. We create an NSPasteboardItem
 *   3. We register ourselves as the data provider (promise pattern)
 *   4. We begin a dragging session with NSDraggingItem
 *   5. User drags to FCP timeline
 *   6. FCP requests the data → pasteboard:item:provideDataForType: called
 *   7. We provide the stored XML data
 *   8. Drag completes → draggingSession:endedAtPoint:operation: called
 *
 * WHY THE PROMISE PATTERN:
 *   - XML files can be large (100MB+ for complex projects)
 *   - Don't copy data unless destination actually wants it
 *   - More efficient: data is only provided when FCP requests it
 *   - Standard pattern for all FCP Workflow Extensions
 *
 * EDUCATIONAL NOTE ON PROMISES:
 *   Instead of copying the XML data immediately to the pasteboard (expensive),
 *   we "promise" to provide it later. This is done via:
 *   - setDataProvider:forTypes: (we promise we'll provide data)
 *   - pasteboard:item:provideDataForType: (fulfilling the promise)
 *
 * SEE ALSO:
 *   - Apple's "Supporting Drag and Drop Through File Promises"
 *   - WEScaffoldDropButton.mm for the reverse direction (receiving from FCP)
 *   - XMCamFlattenerBoxView.mm (reference implementation)
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import <Cocoa/Cocoa.h>

@class WEScaffoldController;

/******************************************************************************
 * WEScaffoldDragBox
 *
 * EDUCATIONAL NOTE:
 *   Extends NSBox (a standard Cocoa box/container control)
 *   Adopts two protocols:
 *   - NSDraggingSource: Required for initiating drags
 *   - NSPasteboardItemDataProvider: Required for promise pattern
 *
 *   We use NSBox because:
 *   - Can contain other views (labels, images)
 *   - Has built-in border drawing
 *   - Simple container for drag source UI
 ******************************************************************************/
@interface WEScaffoldDragBox : NSBox<NSDraggingSource, NSPasteboardItemDataProvider>
{
@public
    // Controller reference
    // EDUCATIONAL: We need to call back to controller to get the XML data
    IBOutlet WEScaffoldController* controller;
}

//
// NSDraggingSource Protocol Methods
// EDUCATIONAL: These are called automatically during the drag operation
//
- (NSDragOperation)draggingSession:(NSDraggingSession *)session
    sourceOperationMaskForDraggingContext:(NSDraggingContext)context;
- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation;

//
// NSPasteboardItemDataProvider Protocol Methods
// EDUCATIONAL: This is the "promise fulfillment" - called when FCP wants the data
//
- (void)pasteboard:(NSPasteboard *)pasteboard
              item:(NSPasteboardItem *)item
provideDataForType:(NSPasteboardType)type;

//
// Mouse Handling
// EDUCATIONAL: We override mouseDown: to initiate the drag
//
- (void)mouseDown:(NSEvent *)theEvent;

@end
