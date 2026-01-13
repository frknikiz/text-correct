# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **macOS SwiftUI application** built with Xcode 16.4. Despite the project name suggesting text correction functionality, this is currently a fresh template project with minimal implementation.

- **Platform**: macOS 15.4+ (targeted deployment)
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Architecture**: Standard SwiftUI app pattern

## Build Commands

### Building the Project
```bash
# Build from command line
xcodebuild -project text-correct.xcodeproj -scheme text-correct -configuration Debug build

# Build for release
xcodebuild -project text-correct.xcodeproj -scheme text-correct -configuration Release build
```

### Running the App
```bash
# Build and run
xcodebuild -project text-correct.xcodeproj -scheme text-correct -configuration Debug build
open build/Build/Products/Debug/text-correct.app
```

### Cleaning Build Artifacts
```bash
xcodebuild -project text-correct.xcodeproj -scheme text-correct clean
```

## Project Structure

```
text-correct/
├── text-correct/                    # Main app source code
│   ├── text_correctApp.swift        # App entry point (@main)
│   ├── ContentView.swift           # Root view
│   ├── text_correct.entitlements    # App security entitlements
│   └── Assets.xcassets/            # App resources
└── text-correct.xcodeproj/          # Xcode project
```

## Architecture

The app follows the standard SwiftUI application pattern:

- **App Entry**: `text_correctApp.swift` contains the `@main` struct conforming to `App`
- **Root View**: `ContentView.swift` contains the main SwiftUI view
- **Scene Management**: Uses `WindowGroup` for the main scene

## Development Environment

- **Xcode Version**: 16.4
- **Deployment Target**: macOS 15.4
- **Swift Version**: 5.0
- **Bundle Identifier**: `frkn.text-correct`

## Security Entitlements

The app has the following entitlements configured in `text_correct.entitlements`:
- App Sandbox enabled
- User-selected file read-only access (`com.apple.security.files.user-selected.read-only`)

## Development Notes

- This project uses PBXFileSystemSynchronizedRootGroup (Xcode 16 feature) for automatic file synchronization
- SwiftUI Previews are enabled for rapid UI development
- Hardened Runtime is enabled for release builds
- No external package dependencies are currently configured
