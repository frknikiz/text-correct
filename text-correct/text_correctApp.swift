//
//  text_correctApp.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import SwiftUI

// Note: @main removed - main.swift is now the entry point
// This file is kept for reference but not used anymore
struct text_correctApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Empty scene to satisfy SwiftUI requirements
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
    }
}

