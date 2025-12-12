/******************************************************************************
 * WEScaffoldController.h
 *
 * PURPOSE:
 *   Main view controller for the WE Scaffold Workflow Extension.
 *   Manages the extension lifecycle and coordinates between UI components.
 *
 * KEY CONCEPTS FOR DEVELOPERS:
 *   - NSViewController (not NSWindowController) for extensions
 *   - Workflow Extension lifecycle: viewWillAppear, not applicationDidFinishLaunching
 *   - Conditional compilation for app vs. extension behavior
 *   - Controller acts as coordinator between drop button and drag box
 *
 * WORKFLOW SEQUENCE:
 *   1. Extension loads → viewDidLoad called
 *   2. About to show → viewWillAppear called (get window ref here)
 *   3. User drops XML → receiveXMLData: called by drop button
 *   4. User drags out → provideDragData called by drag box
 *   5. Extension closes → viewWillDisappear called
 *
 * WHY THIS APPROACH:
 *   - NSViewController is required for Workflow Extensions (not NSWindowController)
 *   - The window is managed by FCP, we just get a reference to it
 *   - Controller doesn't process data - just stores and retrieves (pass-through)
 *
 * SEE ALSO:
 *   - XMCamFlattenerController.mm (reference implementation)
 *   - WEScaffoldDropButton.h (calls receiveXMLData:)
 *   - WEScaffoldDragBox.h (calls provideDragData)
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import <Cocoa/Cocoa.h>

// Forward declarations
@class WEScaffoldDropButton;
@class WEScaffoldDragBox;
@class WEScaffoldWindowDelegate;

/******************************************************************************
 * WEScaffoldController
 *
 * EDUCATIONAL NOTE:
 *   Extends NSViewController (required for Workflow Extensions).
 *   Adopts NSApplicationDelegate for standalone app mode only.
 *
 *   The same controller class is used for both:
 *   - Standalone app (with NSApplicationDelegate methods)
 *   - Workflow Extension (with NSViewController lifecycle)
 *
 *   Conditional compilation (#if WORKFLOW_EXTENSION) handles the differences.
 ******************************************************************************/
@interface WEScaffoldController : NSViewController<NSApplicationDelegate>
{
@public
    //
    // UI Components
    // EDUCATIONAL: These are connected in Interface Builder via "outlets"
    // IBOutlet means "this will be connected to a UI element in the XIB file"
    //
    IBOutlet NSWindow* myWindow;                    // Window (nil in WE mode - get via self.view.window)
    IBOutlet WEScaffoldDropButton* dropButton;      // Drop zone for receiving XML
    IBOutlet WEScaffoldDragBox* dragBox;            // Drag source for sending XML back
    IBOutlet NSTextField* statusLabel;              // Shows current state
    IBOutlet NSTextField* timestampLabel;           // Shows when XML was received
}

//
// Lifecycle Methods (NSViewController)
// EDUCATIONAL: These are called automatically by the system at specific times
//
- (void)viewDidLoad;                    // Called once when view loads from XIB
- (void)viewWillAppear;                 // Called each time view is about to show
- (void)viewWillDisappear;              // Called when view is about to hide

//
// XML Handling Methods
// EDUCATIONAL: Called by drop button and drag box to coordinate data flow
//
- (void)receiveXMLData:(NSData*)xmlData;    // Called by drop button after drop
- (NSData*)provideDragData;                  // Called by drag box before drag

//
// UI Update Methods
//
- (void)updateStatus:(NSString*)status;     // Update status label
- (void)updateTimestamp;                     // Update timestamp label

//
// Application Delegate Methods (Standalone App Only)
// EDUCATIONAL: These are only used when running as standalone app, not in WE mode
//
#if !WORKFLOW_EXTENSION
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
#endif

@end
