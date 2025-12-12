/******************************************************************************
 * WEScaffoldWindowDelegate.mm
 *
 * PURPOSE:
 *   Implementation of window delegate for WE Scaffold.
 *   Handles window resize events to adjust UI layout.
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import "WEScaffoldWindowDelegate.h"
#import "WEScaffoldController.h"
#import "WEScaffoldGlobals.h"

@implementation WEScaffoldWindowDelegate

/******************************************************************************
 * windowDidResize:
 *
 * WHEN CALLED:
 *   Whenever FCP resizes the extension window.
 *
 * PURPOSE:
 *   Adjust our UI layout to fit the new window size.
 *
 * EDUCATIONAL NOTE:
 *   In a Workflow Extension, FCP controls the window size. The user can
 *   resize the extension window, and we get this callback to respond.
 *
 *   For the scaffold, we keep it simple - the XIB's Auto Layout handles
 *   most of the work. This delegate is here as a hook for more complex
 *   layout needs in derived projects.
 ******************************************************************************/
- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow* window = [notification object];
    NSRect windowFrame = [window frame];

    LIFECYCLE_LOG("windowDidResize:");
    LIFECYCLE_LOG("  └─ New size: %.0f x %.0f", windowFrame.size.width, windowFrame.size.height);

    //
    // For the scaffold, Auto Layout handles resizing
    // EDUCATIONAL: In a more complex WE, you'd adjust component positions here
    //
    // Example of manual layout (not needed for scaffold):
    // [controller->dragBox setFrame:NSMakeRect(x, y, width, height)];
}

/******************************************************************************
 * windowWillClose:
 *
 * WHEN CALLED:
 *   When the extension window is about to close.
 *
 * PURPOSE:
 *   Optional cleanup before window closes.
 *
 * EDUCATIONAL NOTE:
 *   The controller's viewWillDisappear handles most cleanup.
 *   This is here as a hook for window-specific cleanup if needed.
 ******************************************************************************/
- (void)windowWillClose:(NSNotification *)notification
{
    LIFECYCLE_LOG("windowWillClose: called");
    // Cleanup handled in controller's viewWillDisappear
}

@end
