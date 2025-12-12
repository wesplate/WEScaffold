/******************************************************************************
 * WEScaffoldGlobals.cpp
 *
 * PURPOSE:
 *   Implementation of global state initialization and cleanup.
 *
 * EDUCATIONAL NOTE:
 *   This file defines the actual global instance and implements the lifecycle
 *   methods. The Initialize() method sets up logging - this is called once
 *   at application/extension startup.
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#include "WEScaffoldGlobals.h"
#import <Foundation/Foundation.h>
#include <sys/stat.h>

/******************************************************************************
 * Global Instance Definition
 *
 * EDUCATIONAL NOTE:
 *   This is where the actual variable is created. Because it's not 'extern',
 *   this allocates storage for the struct. All other files see it via the
 *   'extern' declaration in the header.
 ******************************************************************************/
WEScaffoldGlobals xGlobals = {
    .xmlData = NULL,
    .syslog = NULL,
    .receivedTimestamp = NULL,
    .dataSize = 0,
    .hasData = false
};

/******************************************************************************
 * Initialize
 *
 * WHEN CALLED:
 *   Once at application/extension startup, before any UI is shown.
 *
 * PURPOSE:
 *   Set up the logging infrastructure. Creates the log directory if needed
 *   and opens the log file for writing.
 *
 * EDUCATIONAL NOTE:
 *   We create the log file in ~/Library/Logs/WEScaffold/ which is the
 *   standard location for application logs on macOS. This makes it easy
 *   for developers to find and review logs after testing.
 *
 *   The file is opened in "write" mode, which overwrites any previous log.
 *   If you want to append instead, change "w" to "a".
 ******************************************************************************/
void WEScaffoldGlobals::Initialize()
{
    LIFECYCLE_LOG("Initializing WEScaffold globals...");

    //
    // Set up log file path
    // EDUCATIONAL: We use NSString for easy path manipulation, then convert to C string
    //
    NSString* homeDir = NSHomeDirectory();
    NSString* logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/WEScaffold"];
    NSString* logPath = [logDir stringByAppendingPathComponent:@"wescaffold.log"];

    //
    // Create log directory if it doesn't exist
    // EDUCATIONAL: mkdir with mode 0755 = rwxr-xr-x (read/write/execute for owner, read/execute for others)
    //
    const char* logDirCStr = [logDir fileSystemRepresentation];
    struct stat st = {0};
    if (stat(logDirCStr, &st) == -1) {
        LIFECYCLE_LOG("Creating log directory: %s", logDirCStr);
        mkdir(logDirCStr, 0755);
    }

    //
    // Open log file
    // EDUCATIONAL: fopen returns NULL if it fails. We check this and log to console if file open fails.
    //
    const char* logPathCStr = [logPath fileSystemRepresentation];
    xGlobals.syslog = fopen(logPathCStr, "w");

    if (xGlobals.syslog) {
        LIFECYCLE_LOG("Log file opened: %s", logPathCStr);

        // Write header to log file
        fprintf(xGlobals.syslog, "================================================================================\n");
        fprintf(xGlobals.syslog, "WE Scaffold - Workflow Extension Logging\n");
        fprintf(xGlobals.syslog, "Started: %s", [[NSDate date] description].UTF8String);
        fprintf(xGlobals.syslog, "\n================================================================================\n\n");
        fflush(xGlobals.syslog);
    } else {
        NSLog(@"[WEScaffold] [ERROR] Failed to open log file: %s", logPathCStr);
    }

    //
    // Initialize data fields to empty state
    //
    xGlobals.xmlData = NULL;
    xGlobals.receivedTimestamp = NULL;
    xGlobals.dataSize = 0;
    xGlobals.hasData = false;

    LIFECYCLE_LOG("Initialization complete");
}

/******************************************************************************
 * Cleanup
 *
 * WHEN CALLED:
 *   At application/extension shutdown.
 *
 * PURPOSE:
 *   Release all resources (memory and file handles) to prevent leaks.
 *
 * EDUCATIONAL NOTE:
 *   This is the counterpart to Initialize(). We must:
 *   1. Release any CFDataRef we're holding (if not NULL)
 *   2. Release timestamp string (if not NULL)
 *   3. Close the log file (if open)
 *
 *   Always check for NULL before calling CFRelease - releasing NULL will crash!
 ******************************************************************************/
void WEScaffoldGlobals::Cleanup()
{
    LIFECYCLE_LOG("Cleaning up WEScaffold globals...");

    //
    // Release XML data if we have it
    // EDUCATIONAL: CFRelease decrements the retain count. If it reaches 0, the object is freed.
    //
    if (xGlobals.xmlData != NULL) {
        DATA_LOG("Releasing xmlData (was %zu bytes)", xGlobals.dataSize);
        CFRelease(xGlobals.xmlData);
        xGlobals.xmlData = NULL;
    }

    //
    // Release timestamp string if we have it
    //
    if (xGlobals.receivedTimestamp != NULL) {
        CFRelease(xGlobals.receivedTimestamp);
        xGlobals.receivedTimestamp = NULL;
    }

    //
    // Close log file
    // EDUCATIONAL: Always close files you've opened to flush buffers and release OS resources
    //
    if (xGlobals.syslog) {
        fprintf(xGlobals.syslog, "\n================================================================================\n");
        fprintf(xGlobals.syslog, "WEScaffold shutting down\n");
        fprintf(xGlobals.syslog, "================================================================================\n");
        fclose(xGlobals.syslog);
        xGlobals.syslog = NULL;
    }

    // Reset state
    xGlobals.dataSize = 0;
    xGlobals.hasData = false;

    LIFECYCLE_LOG("Cleanup complete");
}
