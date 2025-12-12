/******************************************************************************
 * WEScaffoldGlobals.h
 *
 * PURPOSE:
 *   Global state management for the WE Scaffold Workflow Extension.
 *   Provides centralized storage for XML data and logging infrastructure.
 *
 * KEY CONCEPTS FOR DEVELOPERS:
 *   - Singleton pattern: One global instance (xGlobals) shared across all components
 *   - CFDataRef: Core Foundation data type for explicit memory management
 *   - plog: Automatic Duck's logging system (writes to file)
 *   - Educational logging macros for tracking execution flow
 *
 * WHY THIS APPROACH:
 *   - Drop button and drag box are separate objects that need to share data
 *   - Global state is simplest pattern for a minimal scaffold
 *   - Using struct (not class) keeps it simple and C++-compatible
 *   - Extensive logging teaches developers what's happening at each step
 *
 * SEE ALSO:
 *   - WEScaffoldDropButton.mm (stores data here after drop)
 *   - WEScaffoldDragBox.mm (retrieves data from here for drag)
 *   - share/plog.h (logging implementation)
 *
 * Copyright 2025 Automatic Duck, Inc.
 ******************************************************************************/

#ifndef __WEScaffoldGlobals_h__
#define __WEScaffoldGlobals_h__

#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

// Need Foundation for NSLog in logging macros
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

/******************************************************************************
 * WEScaffoldGlobals Structure
 *
 * EDUCATIONAL NOTE:
 *   This is a plain C struct, not a C++ class. This makes it compatible with
 *   both Objective-C and C++ code. All the fields are public, which is fine
 *   for a scaffold - if you need encapsulation later, convert to a class.
 ******************************************************************************/
typedef struct WEScaffoldGlobals {
    //
    // XML Data Storage
    // EDUCATIONAL: We use CFDataRef (Core Foundation) instead of NSData* because:
    // 1. Explicit memory management teaches ownership (CFRetain/CFRelease)
    // 2. Works in C++ code without Objective-C++
    // 3. Can bridge to NSData* with simple cast when needed
    //
    CFDataRef xmlData;              // The FCPXML being passed through (owned - must CFRelease)

    //
    // Logging Infrastructure
    // EDUCATIONAL: Dual logging system for maximum developer visibility
    //
    FILE* syslog;                   // Log file handle (opened by Initialize())

    //
    // Metadata
    // EDUCATIONAL: Track when data was received for debugging/logging
    //
    CFStringRef receivedTimestamp;  // When XML was received (e.g., "2025-11-25 14:32:17")
    size_t dataSize;                // Cached size of xmlData (for quick logging)
    bool hasData;                   // Quick validity check without null pointer testing

    //
    // Lifecycle Methods
    //
    void Initialize();              // Called once at app/extension startup
    void Cleanup();                 // Called at shutdown to release resources

} WEScaffoldGlobals;

/******************************************************************************
 * Global Instance
 *
 * EDUCATIONAL NOTE:
 *   The 'extern' keyword means "this variable is defined elsewhere" (in .cpp file).
 *   Every file that includes this header can access the same global instance.
 *   This is the simplest form of singleton pattern in C.
 ******************************************************************************/
extern WEScaffoldGlobals xGlobals;

/******************************************************************************
 * Logging Macros
 *
 * PURPOSE:
 *   Provide categorized, dual-output logging (console + file) for developer education.
 *
 * EDUCATIONAL NOTE:
 *   These macros make it easy to see what's happening at each step of the
 *   workflow extension lifecycle. Each category gets a distinct prefix:
 *   - [LIFECYCLE] - Extension loading/unloading
 *   - [DROP]      - Receiving XML from FCP
 *   - [DRAG]      - Sending XML back to FCP
 *   - [DATA]      - XML data analysis
 *   - [ERROR]     - Problems encountered
 *
 * USAGE:
 *   LIFECYCLE_LOG("viewWillAppear called");
 *   DROP_LOG("Received XML: %ld bytes", xmlData.length);
 *   DATA_LOG("Stored CFDataRef at: %p", xGlobals.xmlData);
 ******************************************************************************/

// Base logging macro - logs to both NSLog (console) and plog (file)
// The do-while(0) pattern allows the macro to be used like a function with semicolon
#define SCAFFOLD_LOG(fmt, ...) \
    do { \
        NSLog(@"[WEScaffold] " fmt, ##__VA_ARGS__); \
        if (xGlobals.syslog) { \
            fprintf(xGlobals.syslog, "[WEScaffold] " fmt "\n", ##__VA_ARGS__); \
            fflush(xGlobals.syslog); \
        } \
    } while(0)

// Category-specific macros for clarity
#define LIFECYCLE_LOG(fmt, ...) SCAFFOLD_LOG("[LIFECYCLE] " fmt, ##__VA_ARGS__)
#define DROP_LOG(fmt, ...)      SCAFFOLD_LOG("[DROP] " fmt, ##__VA_ARGS__)
#define DRAG_LOG(fmt, ...)      SCAFFOLD_LOG("[DRAG] " fmt, ##__VA_ARGS__)
#define DATA_LOG(fmt, ...)      SCAFFOLD_LOG("[DATA] " fmt, ##__VA_ARGS__)
#define ERROR_LOG(fmt, ...)     SCAFFOLD_LOG("[ERROR] " fmt, ##__VA_ARGS__)

#endif // __WEScaffoldGlobals_h__
