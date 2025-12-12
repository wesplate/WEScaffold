/******************************************************************************
 * main.cpp
 *
 * PURPOSE:
 *   Main entry point for the WEScaffold standalone application.
 *
 * EDUCATIONAL NOTE:
 *   This file is ONLY compiled for the app target, not the extension target.
 *   The extension uses ProExtensionMain as its entry point (linked via -u _ProExtensionMain).
 *
 *   We use conditional compilation (#if WORKFLOW_EXTENSION) to exclude this
 *   entire file when building the extension.
 *
 * WHY THIS APPROACH:
 *   - The standalone app needs a main() function
 *   - The Workflow Extension does NOT - it's loaded by FCP
 *   - Same source code builds both targets with different entry points
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#import <Cocoa/Cocoa.h>
#include "WEScaffoldGlobals.h"

#if !WORKFLOW_EXTENSION

/******************************************************************************
 * main
 *
 * WHEN CALLED:
 *   By macOS when the user launches the standalone .app
 *
 * PURPOSE:
 *   Standard Cocoa application entry point. Initializes global state and
 *   hands control to NSApplicationMain.
 *
 * EDUCATIONAL NOTE:
 *   NSApplicationMain loads the main menu NIB, creates the app delegate,
 *   and runs the event loop. It never returns (until app quits).
 *
 *   This is the standard pattern for all Cocoa applications.
 ******************************************************************************/
int main(int argc, const char * argv[])
{
    // Initialize global state before app runs
    // EDUCATIONAL: This sets up logging so we can see what happens during launch
    xGlobals.Initialize();

    LIFECYCLE_LOG("===========================================");
    LIFECYCLE_LOG("WEScaffold Standalone App Starting");
    LIFECYCLE_LOG("===========================================");
    LIFECYCLE_LOG("Note: This is the standalone app, not the Workflow Extension");
    LIFECYCLE_LOG("The extension runs inside Final Cut Pro");

    // Standard Cocoa app entry point
    // EDUCATIONAL: This function loads the app, shows windows, and doesn't return until quit
    return NSApplicationMain(argc, argv);
}

#else

/******************************************************************************
 * WORKFLOW EXTENSION MODE
 *
 * EDUCATIONAL NOTE:
 *   When building the extension target, WORKFLOW_EXTENSION=1 is defined.
 *   The extension doesn't need main() - ProExtensionMain is the entry point.
 *   We still define xGlobals here so it's available to all extension code.
 ******************************************************************************/

// Empty file for extension - ProExtensionMain is linked via -u _ProExtensionMain

#endif // !WORKFLOW_EXTENSION
