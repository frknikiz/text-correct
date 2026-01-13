# Crash Fixes Summary

## Issue Fixed

### EXC_BAD_ACCESS Crash (CRITICAL - FIXED)
**Error**: `Thread 1: EXC_BAD_ACCESS (code=1, address=0x20)`

**Root Cause**: Memory access violation when closing windows due to async closures accessing deallocated memory during SwiftUI view deallocation.

## Problem Details

When users closed windows (Settings, Debug, Onboarding), the app crashed with `EXC_BAD_ACCESS (code=1, address=0x20)`. This was caused by a race condition:

1. User clicked "Kapat" button or window close button
2. `window.close()` was called (sometimes wrapped in async dispatch)
3. This triggered `windowWillClose` delegate method
4. Delegate method scheduled async closure: `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)`
5. Meanwhile, SwiftUI started deallocating the NSHostingController and View hierarchy
6. The delayed async closure tried to access `self.logger` and other properties
7. **CRASH**: Accessing deallocated memory → EXC_BAD_ACCESS at address 0x20

## Fix Applied

Based on Stack Overflow guidance ([https://stackoverflow.com/questions/12437605/thread-1-exc-bad-access-code-1-address-0x30000008-issue-generated](https://stackoverflow.com/questions/12437605/thread-1-exc-bad-access-code-1-address-0x30000008-issue-generated)) and Medium article about debugging data races with Thread Sanitizer, the solution was to **eliminate async operations during window close**:

### Changes Made

1. **AppDelegate.swift - windowWillClose delegate**:
   - Changed from: `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { ... }`
   - Changed to: Synchronous `setupMenu()` call
   - Added comment explaining Stack Overflow guidance

2. **AppDelegate.swift - statusBarButtonClicked**:
   - Kept the async closure for popover display (0.1s delay for menu close)
   - Changed menu restoration from async to synchronous
   - No more delayed menu restoration

3. **SettingsView.swift - closeWindow()**:
   - Removed: `DispatchQueue.main.async` wrapper
   - Changed to: Direct `window.close()` call
   - No more async dispatch during window close

## Why This Fixes the Data Race

The async delays were creating a time window where:
- SwiftUI could deallocate the view hierarchy
- Async closures would try to access deallocated memory
- Result: EXC_BAD_ACCESS crash

By making operations synchronous:
- Window close completes
- Menu restoration completes
- **Then** SwiftUI safely deallocates the view hierarchy
- No race conditions possible because there's no async delay

## Testing

The fix has been tested and confirmed to resolve the crash:
- Opening and closing Settings window ✓
- Opening and closing Debug window ✓
- App continues running in menu bar after window close ✓
- No more EXC_BAD_ACCESS crashes ✓

## References

- [Stack Overflow: Thread 1 EXC_BAD_ACCESS debugging](https://stackoverflow.com/questions/12437605/thread-1-exc-bad-access-code-1-address-0x30000008-issue-generated)
- [Medium: Debugging iOS Data Race Errors Using Thread Sanitizer](https://medium.com/@sarthak.tayade/debugging-ios-data-race-exc-bad-access-errors-using-thread-sanitizer-tsan-66821f68d7c1)
