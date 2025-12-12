/******************************************************************************
 * WEScaffoldDropButton.h
 *
 * PURPOSE:
 *   Drop zone button that receives FCPXML from Final Cut Pro via drag and drop.
 *   This is the "input" side of the Workflow Extension bidirectional pattern.
 *
 * KEY CONCEPTS FOR DEVELOPERS:
 *   - NSDraggingDestination protocol: How macOS handles drag and drop
 *   - Pasteboard types: "com.apple.finalcutpro.xml" is the FCP identifier
 *   - Validation: Must check types in draggingEntered: before accepting
 *   - Data extraction: Use [pboard dataForType:] to get NSData from pasteboard
 *
 * WORKFLOW SEQUENCE:
 *   1. User starts drag in Final Cut Pro (event, project, or compound clip)
 *   2. FCP looks for Workflow Extensions accepting FCPXML pasteboard type
 *   3. As mouse enters our drop zone:
 *      - draggingEntered: is called
 *      - We validate the pasteboard type
 *      - Return NSDragOperationCopy to show "+" cursor
 *   4. While hovering:
 *      - draggingUpdated: called repeatedly (we keep validating)
 *   5. User releases mouse:
 *      - prepareForDragOperation: called (we return YES)
 *      - performDragOperation: called (we extract and store the data)
 *   6. Data is now in xGlobals.xmlData ready for processing or drag back
 *
 * WHY A PROMISE PATTERN ISN'T NEEDED HERE:
 *   - This is the RECEIVER side - we get actual NSData immediately
 *   - The promise pattern is only for SENDING data (see WEScaffoldDragBox.mm)
 *   - FCP provides complete XML when dropped, not a promise
 *
 * SEE ALSO:
 *   - Apple's "Supporting Drag and Drop to Receive Final Cut Pro Data"
 *   - WEScaffoldDragBox.mm for the reverse direction (sending back to FCP)
 *   - WEScaffoldController.mm for the overall data flow
 *   - XMCamFlattenerDropButton.mm (reference implementation)
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import <Cocoa/Cocoa.h>

@class WEScaffoldController;

//
// Pasteboard Type Constant
// EDUCATIONAL: This is the UTI (Uniform Type Identifier) that FCP uses for FCPXML
// The ".xml" suffix means "give me the most recent version you support"
//
#define FCP_XML_PBOARD_TYPE @"com.apple.finalcutpro.xml"

/******************************************************************************
 * WEScaffoldDropButton
 *
 * EDUCATIONAL NOTE:
 *   Extends NSButton (a standard Cocoa button control)
 *   Adopts NSDraggingDestination protocol (required for accepting drops)
 *
 *   We use NSButton instead of NSView because:
 *   - Can display images (drop instructions, hover state)
 *   - Has built-in visual feedback
 *   - Simpler than managing a custom view
 ******************************************************************************/
@interface WEScaffoldDropButton : NSButton<NSDraggingDestination>
{
@public
    // Controller reference
    // EDUCATIONAL: We need to call back to the controller to store the dropped data
    IBOutlet WEScaffoldController* controller;

    // Visual state
    NSImage* dropInstructionsImage;     // Default state: "Drop FCPXML Here"
    NSImage* dropHoverImage;            // Hover state: "Ready to Receive"
}

//
// NSDraggingDestination Protocol Methods
// EDUCATIONAL: These are called automatically by the system during drag operations
//
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender;
- (void)draggingExited:(id<NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender;

//
// UI Helper Methods
//
- (void)showHoverState:(BOOL)hover;     // Switch between instruction and hover images

@end
