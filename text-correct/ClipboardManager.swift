//
//  ClipboardManager.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()

    private let pasteboard = NSPasteboard.general

    private init() {}

    func copyToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func readFromClipboard() -> String? {
        return pasteboard.string(forType: .string)
    }
}
