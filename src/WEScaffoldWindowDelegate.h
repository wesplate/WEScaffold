/******************************************************************************
 * WEScaffoldWindowDelegate.h
 *
 * PURPOSE:
 *   Window delegate for handling resize events in the Workflow Extension.
 *
 * EDUCATIONAL NOTE:
 *   In Workflow Extension mode, FCP manages the window and can resize it.
 *   We install this delegate to handle those resize events and adjust our
 *   UI layout accordingly.
 *
 * WHY THIS APPROACH:
 *   - Auto Layout might not be fully configured for dynamic resizing
 *   - Manual layout gives us full control over component positioning
 *   - Demonstrates the window delegate pattern for WE development
 *
 * SEE ALSO:
 *   - XMCamFlattenerWindowDelegate.h (reference implementation)
 *   - WEScaffoldController.mm (installs this delegate in viewWillAppear)
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import <Cocoa/Cocoa.h>

@class WEScaffoldController;

@interface WEScaffoldWindowDelegate : NSObject<NSWindowDelegate>
{
@public
    // Controller reference
    // EDUCATIONAL: We need a reference back to the controller to access UI elements
    WEScaffoldController* controller;
}

@end
