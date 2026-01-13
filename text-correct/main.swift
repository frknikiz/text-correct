//
//  main.swift
//  text-correct
//
//  Pure AppKit implementation for Services support
//

import Cocoa

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.delegate = appDelegate

NSLog("🚀 DevTurkceFix: Starting with pure AppKit (no SwiftUI)")
NSLog("DevTurkceFix: Services port will be opened automatically")

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
