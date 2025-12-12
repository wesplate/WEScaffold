# Xcode Project Setup Guide for WE Scaffold

## Overview

This guide walks you through creating the Xcode project, XIB files, and visual assets to complete the WE Scaffold. All source code and configuration files are already created - you just need to wire them together in Xcode.

## Prerequisites

- Xcode 14+ installed
- Command Line Tools installed
- All source files in `WEScaffold/src/`
- All configuration files in `WEScaffold/mac/`

## Part 1: Create Xcode Project

### Step 1: Create New Project

1. Open Xcode
2. File → New → Project
3. Choose **macOS** → **App**
4. Click **Next**

### Step 2: Configure App Target

- **Product Name:** WEScaffold
- **Team:** (your team)
- **Organization Identifier:** com.automaticduck
- **Bundle Identifier:** com.automaticduck.WEScaffold
- **Language:** Objective-C
- **User Interface:** XIB
- **Click Next**, save to: `/Users/wes/dev/AutomaticDuckII/WEScaffold/mac/`

### Step 3: Add Extension Target

1. In project navigator, select the WEScaffold project (blue icon at top)
2. At bottom of target list, click **+** button
3. Choose **macOS** → **App Extension**
4. Find and select **Workflow Extension** template (or use generic Extension if not available)
5. Click **Next**

Configure extension target:
- **Product Name:** WEScaffoldWE
- **Bundle Identifier:** com.automaticduck.WEScaffoldWE
- **Language:** Objective-C
- **Click Finish**

### Step 4: Delete Template Files

Xcode created template files we don't need:

**Delete from App target:**
- `main.m` (we have `main.cpp`)
- `AppDelegate.h/m` (not needed)
- `MainMenu.xib` (we'll create our own)

**Delete from Extension target:**
- Any template view controller files
- Template XIB file

### Step 5: Add Source Files

**Select WEScaffold target** in project navigator:

1. Right-click on WEScaffold group → Add Files to "WEScaffold"
2. Navigate to `WEScaffold/src/`
3. Select ALL `.h`, `.mm`, `.cpp` files
4. **Important:** Check these options:
   - ✅ Copy items if needed (UNCHECKED - files are already in place)
   - ✅ Create groups
   - ✅ Add to targets: **WEScaffold** (checked)
   - ✅ Add to targets: **WEScaffoldWE** (checked)
5. Click **Add**

### Step 6: Configure Build Settings for App Target

Select **WEScaffold** target → Build Settings:

**Search for "Header Search Paths":**
```
$(HOME)/AutomaticDuckII/share
$(HOME)/AutomaticDuckII/share/xml
$(HOME)/AutomaticDuckII/share/files
$(HOME)/AutomaticDuckII/share/str
/usr/include/libxml2
```

**Search for "Framework Search Paths":**
```
/System/Library/PrivateFrameworks
```

**Search for "Other Linker Flags":**
```
-framework Cocoa
-framework QuartzCore
```

**Search for "Preprocessor Macros":**
- Debug: `DEBUG=1 AD=$(HOME)/AutomaticDuckII`
- Release: `AD=$(HOME)/AutomaticDuckII`

**Search for "C++ Language Dialect":**
- C++11 or later

**Search for "Deployment Target":**
- macOS 14.0

**Search for "Architectures":**
- Standard Architectures (arm64, x86_64)

### Step 7: Configure Build Settings for Extension Target

Select **WEScaffoldWE** target → Build Settings:

**Same as App target, PLUS:**

**Search for "Other Linker Flags" (ADD to existing):**
```
-lProExtension
-u _ProExtensionMain
```

**Search for "Preprocessor Macros" (ADD to existing):**
- Debug: `DEBUG=1 WORKFLOW_EXTENSION=1 AD=$(HOME)/AutomaticDuckII`
- Release: `WORKFLOW_EXTENSION=1 AD=$(HOME)/AutomaticDuckII`

### Step 8: Exclude main.cpp from Extension Target

1. In project navigator, select `main.cpp`
2. In File Inspector (right panel), find "Target Membership"
3. **UNCHECK** WEScaffoldWE (main.cpp only for app, not extension)
4. Keep WEScaffold checked

### Step 9: Set Info.plist Files

**WEScaffold target → General tab:**
- Custom iOS Target Properties → Browse → select `WEScaffold/mac/Info.plist`

**WEScaffoldWE target → General tab:**
- Custom iOS Target Properties → Browse → select `WEScaffold/mac/WEScaffoldWE/Info.plist`

### Step 10: Set Entitlements

**WEScaffold target → Signing & Capabilities:**
- Click **+ Capability** → App Sandbox
- This creates an entitlements file
- Replace it with our custom one:
  - Build Settings → search "Code Signing Entitlements"
  - Set to: `WEScaffold/mac/WEScaffold.entitlements`

**WEScaffoldWE target → Signing & Capabilities:**
- Same process
- Set to: `WEScaffold/mac/WEScaffoldWE.entitlements`

### Step 11: Embed Extension in App

**WEScaffold target → General tab:**
- Scroll to "Frameworks, Libraries, and Embedded Content"
- Click **+**
- Select **WEScaffoldWE.appex**
- Change "Embed" to **Embed & Sign**

## Part 2: Create XIB Files

### Create WEScaffold.xib (Standalone App UI)

1. File → New → File
2. macOS → User Interface → View
3. Save as: `WEScaffold.xib` in `WEScaffold/rsrc/Base.lproj/`
4. Add to WEScaffold target only

**Design the interface:**

1. In Object Library, drag **Window** onto canvas
2. Set window properties (Size Inspector):
   - Width: 400
   - Height: 200
3. Drag **Text Field** (label) onto window:
   - Text: "WE Scaffold Workflow Extension"
   - Font: System Bold 18
   - Alignment: Center
4. Drag another **Text Field** below:
   - Text: "Use Window → Extensions → WE Scaffold in Final Cut Pro"
   - Font: System 14
   - Alignment: Center
5. Auto Layout: Center both labels horizontally and vertically

**Set File's Owner:**
1. Select File's Owner in outline
2. Identity Inspector → Custom Class: `WEScaffoldController`

**Connect to window outlet:**
1. Control-drag from File's Owner to Window
2. Select `myWindow` outlet

### Create WEScaffoldWE.xib (Workflow Extension UI)

1. File → New → File
2. macOS → User Interface → View
3. Save as: `WEScaffoldWE.xib` in `WEScaffold/rsrc/Base.lproj/`
4. Add to WEScaffoldWE target only

**Design the interface:**

1. Main View should be ~300x400 points

**Add Drop Zone (Top Half):**

2. Drag **Button** (NSButton) onto view
   - Position: x=10, y=200
   - Size: width=280, height=120
   - Style: Square (in Attributes Inspector)
   - Image: (will add later)
   - Identity Inspector → Custom Class: `WEScaffoldDropButton`

3. Below button, drag **Text Field** (label):
   - Text: "Status: Ready"
   - Bind to outlet: `statusLabel`

4. Below that, drag another **Text Field**:
   - Text: "" (empty)
   - Bind to outlet: `timestampLabel`

**Add Drag Zone (Bottom Half):**

5. Drag **Box** (NSBox) onto view
   - Position: x=10, y=20
   - Size: width=280, height=120
   - Title: "Drag to FCP"
   - Identity Inspector → Custom Class: `WEScaffoldDragBox`

6. Inside the box, drag **Text Field**:
   - Text: "Drop XML above first"
   - Center in box

**Set File's Owner:**
1. Select File's Owner
2. Identity Inspector → Custom Class: `WEScaffoldController`

**Connect Outlets:**

Control-drag from File's Owner to each element:
- File's Owner → Drop Button → Connect to `dropButton`
- File's Owner → Drag Box → Connect to `dragBox`
- File's Owner → Status Label → Connect to `statusLabel`
- File's Owner → Timestamp Label → Connect to `timestampLabel`

**Connect Controller References:**

1. Select the Drop Button
2. Connections Inspector → `controller` outlet
3. Drag to File's Owner

4. Repeat for Drag Box:
   - Select Drag Box
   - Controller outlet → File's Owner

## Part 3: Create Visual Assets

### Option A: Simple Text-Based Images (Quick)

Create simple PNG files with text using any graphics tool:

**DropInstructions.png (280x100):**
- Background: Light gray (#F0F0F0)
- Border: Dashed, dark gray
- Text: "Drop FCPXML Here" (centered, 16pt)

**DropInstructions@2x.png (560x200):**
- Same as above, double resolution

**DropHover.png (280x100):**
- Background: Light blue (#E0E8FF)
- Border: Solid, blue
- Text: "Ready to Receive" (centered, 16pt)

**DropHover@2x.png (560x200):**
- Same as above, double resolution

Save all in: `WEScaffold/rsrc/`

### Option B: Programmatic (No Images Needed)

Skip creating images and modify `WEScaffoldDropButton.mm`:

```objc
- (void)awakeFromNib {
    // ... existing code ...

    // Instead of loading images, just use text
    [self setTitle:@"Drop FCPXML Here"];
}

- (void)showHoverState:(BOOL)hover {
    if (hover) {
        [self setTitle:@"Ready to Receive"];
    } else {
        [self setTitle:@"Drop FCPXML Here"];
    }
}
```

### Add Assets to Project

1. In Xcode, right-click on project
2. Add Files to "WEScaffold"
3. Select the PNG files from `WEScaffold/rsrc/`
4. Add to both targets

## Part 4: Build and Test

### Build the Project

1. Select scheme: **WEScaffold**
2. Product → Build (⌘B)

**Fix any build errors:**
- Missing headers? Check Header Search Paths
- Linker errors? Check Other Linker Flags
- Can't find main? Make sure main.cpp is only in app target

### Run Standalone App

1. Product → Run (⌘R)
2. Should see window with "Use as FCP Extension" message
3. Check Console for logs:
   ```
   [LIFECYCLE] WEScaffold Standalone App Starting
   ```

### Test in Final Cut Pro

1. Build successfully
2. Note the build location:
   ```bash
   ~/Library/Developer/Xcode/DerivedData/WEScaffold-*/Build/Products/Debug/WEScaffold.app
   ```
3. Launch Final Cut Pro
4. Window → Extensions
5. Look for "WE Scaffold" in the list
6. If not there, check FCP console: Window → Show Console

**If extension doesn't appear:**
- Check Info.plist has `NSExtensionPointIdentifier`
- Check extension is sandboxed (entitlements)
- Check bundle ID matches
- Restart FCP

### Test Drag and Drop

1. In FCP, create a simple project
2. Open WE Scaffold extension
3. Drag project from browser onto drop zone
4. Check logs:
   ```bash
   tail -f ~/Library/Logs/WEScaffold/wescaffold.log
   ```
5. Should see `[DROP]` logs with XML size
6. Drag from extension back to timeline
7. Should see `[DRAG]` logs with promise fulfillment

## Part 5: Distribution

### Archive the App

1. Product → Archive
2. Organizer opens
3. Select archive → Distribute App
4. Choose distribution method:
   - **Development:** For testing
   - **App Store:** For App Store submission
   - **Developer ID:** For distribution outside App Store

### Package Structure

The distributed app should have:
```
WEScaffold.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/WEScaffold
│   ├── Resources/
│   │   ├── *.xib
│   │   └── *.png
│   ├── _CodeSignature/
│   └── PlugIns/
│       └── WEScaffoldWE.appex/
│           ├── Contents/
│           │   ├── Info.plist
│           │   ├── MacOS/WEScaffoldWE
│           │   ├── Resources/
│           │   └── _CodeSignature/
```

### Installation

Users install by:
1. Drag `WEScaffold.app` to `/Applications`
2. Launch Final Cut Pro
3. Window → Extensions → WE Scaffold

FCP automatically discovers the embedded `.appex` and registers it.

## Troubleshooting

### Build Errors

**"ProExtension/ProExtension.h file not found"**
- Add `/System/Library/PrivateFrameworks` to Framework Search Paths
- Extension target only

**"Undefined symbols for architecture arm64: _ProExtensionMain"**
- Add `-u _ProExtensionMain` to Other Linker Flags
- Extension target only

**"No visible @interface for 'WEScaffoldController' declares the selector 'receiveXMLData:'"**
- Check WEScaffoldController.h is in project
- Check file is in both targets

### Runtime Errors

**Extension doesn't appear in FCP**
- Check Console.app for FCP errors
- Verify Info.plist has correct `NSExtensionPointIdentifier`
- Verify sandboxing is enabled
- Try `killall Final\ Cut\ Pro` and relaunch

**Drop doesn't work**
- Check XIB connections (dropButton outlet)
- Check controller outlet in drop button
- Check logs for [DROP] messages

**Drag doesn't work**
- Check XIB connections (dragBox outlet)
- Check controller outlet in drag box
- Verify XML was dropped first
- Check logs for [DRAG] messages

## Summary

You've now created a complete Workflow Extension for Final Cut Pro that:

✅ Appears in FCP's Extensions menu
✅ Accepts FCPXML via drag and drop
✅ Provides extensive logging
✅ Drags XML back to FCP
✅ Serves as a template for future extensions

Next steps:
- Add your own XML processing logic
- Customize the UI
- Add settings/preferences
- Implement your workflow enhancement

Happy developing!
