# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Text Correct** is a macOS menu bar application that provides system-wide Turkish text correction via macOS Services. The app runs as a background service accessible from any application through the right-click context menu.

- **Platform**: macOS 15.4+
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI (for windows) + AppKit (for app lifecycle and Services)
- **Architecture**: Pure AppKit app with SwiftUI views for windows

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

## Architecture

### App Entry Point
- **main.swift**: Pure AppKit entry point (not SwiftUI `@main`). Creates `NSApplication` with `AppDelegate` as delegate.

### Core Components

#### AppDelegate (Central Coordinator)
The `AppDelegate` is the heart of the application, managing:
- **NSStatusItem**: Menu bar icon ("✓ Text") with click handler
- **NSPopover**: Quick status display when clicking menu bar icon
- **Windows**: Settings, Debug, and Onboarding windows
- **macOS Services Registration**: Registers `serviceCorrectText` method with system
- **Service Handler**: `serviceCorrectText(_ pboard:userData:error:)` - the actual text correction logic

#### Service Workflow
1. User selects text in any app
2. Right-click → Services → "✏️ Metni Düzelt"
3. System calls `AppDelegate.serviceCorrectText` with selected text
4. Text sent to OpenAI-compatible API via `OpenAIService`
5. Corrected text written back to pasteboard (replaces selected text)
6. User notification displayed

#### Key Services
- **OpenAIService**: Handles API communication with OpenAI-compatible endpoints
- **APIConfig**: Manages API key, base URL, model (stored in UserDefaults)
- **LogManager**: Centralized logging with in-memory log buffer for Debug window
- **PermissionChecker**: Validates Services registration status

#### Window Management
Critical: All window close operations must be **synchronous** to avoid EXC_BAD_ACCESS crashes during SwiftUI view deallocation. See `CRASH_FIXES.md` for details.

### Configuration System

API configuration is stored in UserDefaults via `APIConfig`:
- `apiKey`: OpenAI-compatible API key
- `baseURL`: API endpoint (default: `https://api.openai.com/v1`)
- `model`: Model name (default: `gpt-4o-mini`)

### System Prompt
The app uses a specific Turkish text correction prompt in `APIConfig.getSystemPrompt()` that instructs the AI to:
- Only fix punctuation, spelling, word errors, capitalization
- Preserve original structure and paragraphs
- Return responses in JSON format: `{"corrected_text": "..."}`

## Security Entitlements

Located in `text_correct.entitlements`:
- App Sandbox: **disabled** (required for Services and Apple Events)
- Network client: enabled (for API calls)
- Apple Events automation: enabled
- User-selected file read-only: enabled

The app uses a **Services-based architecture** which requires broad system access, so sandbox is disabled.

## Info.plist Configuration

The `NSServices` array defines the system service:
- **NSMessage**: `serviceCorrectText` - method name in `AppDelegate`
- **NSPortName**: `text-correct` - bundle identifier
- **NSMenuItem**: Display name "✏️ Metni Düzelt"
- **NSSendTypes/NSReturnTypes**: String pasteboard types

## Development Notes

### Service Registration
Services are registered in `applicationDidFinishLaunching`:
```swift
NSApp.registerServicesMenuSendTypes([.string], returnTypes: [.string])
NSRegisterServicesProvider(self, "text-correct")
NSUpdateDynamicServices()
```

After modifying Services, users may need to:
1. Restart the app
2. Log out/in or run `/System/Library/CoreServices/pbs -flush` to refresh Services cache

### Debugging Services
Use the Debug window (Cmd+D from menu or "Debug Logs" menu item) which includes:
- Live log viewer with filtering
- Service call counter
- "Test Service" button that calls the service method directly
- Logs from `LogManager.shared`

### Window Lifecycle
Windows must set their delegate to `AppDelegate` for proper cleanup:
```swift
window.delegate = self  // Triggers windowWillClose
```

The `windowWillClose` method clears window references and restores the menu bar.

### API Response Format
The OpenAI API must return JSON in this format:
```json
{"corrected_text": "corrected text here"}
```

The system prompt instructs the AI to return only this JSON. The `OpenAIService` handles markdown code blocks around the JSON.

### Logging
Use `LogManager.shared` for consistent logging:
```swift
LogManager.shared.info("Message")
LogManager.shared.error("Error")
```

Logs appear in Debug window and console.
