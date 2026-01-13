//
//  DebugWindow.swift
//  text-correct
//
//  Created by Claude on 10.01.2026.
//

import SwiftUI

struct DebugWindow: View {
    @StateObject private var logManager = LogManager.shared
    @State private var filterLevel: LogLevel?
    @State private var searchText = ""
    @State private var autoscroll: Bool = true

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var filteredLogs: [LogEntry] {
        var result = logManager.logs

        if let filterLevel = filterLevel {
            result = result.filter { $0.level == filterLevel }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Logs")
                        .font(.headline)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(logManager.serviceCallCount > 0 ? .green : .red)
                            .frame(width: 8, height: 8)

                        Text("Service Calls: \(logManager.serviceCallCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("|")
                            .foregroundStyle(.tertiary)

                        Text("🔧 DEV Türkçe Fix")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Text("\(filteredLogs.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Controls
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)

                // Level filter
                Picker("Level", selection: $filterLevel) {
                    Text("All Levels").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Label(level.rawValue, systemImage: level.icon)
                            .tag(level as LogLevel?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                // Autoscroll toggle
                Toggle("Auto-scroll", isOn: $autoscroll)
                    .toggleStyle(.checkbox)

                Spacer()

                // Test Service button
                Button(action: {
                    testServiceMethod()
                }) {
                    Label("Test Service", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                // Clear button
                Button(action: {
                    logManager.clear()
                }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Log entries
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredLogs) { entry in
                            LogEntryView(entry: entry, dateFormatter: dateFormatter)
                                .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: logManager.logs.count) { _, _ in
                    if autoscroll, let lastId = filteredLogs.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Service: 🔧 DEV Türkçe Fix | Select text → Services → 🔧 DEV Türkçe Fix")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func testServiceMethod() {
        logManager.info("========================================")
        logManager.info("🧪 MANUAL TEST: Calling service method...")
        logManager.info("========================================")

        // Get the app delegate using global reference
        if let appDelegate = appDelegateShared {
            let testText = "Test Mesajı"
            logManager.info("Test text: '\(testText)'")

            // Create a test pasteboard
            let pboard = NSPasteboard.general
            pboard.clearContents()
            pboard.setString(testText, forType: .string)
            logManager.info("Test text placed on clipboard")

            // Create error pointer
            var error: NSString? = nil
            let errorPtr = AutoreleasingUnsafeMutablePointer<NSString?>(&error)

            // Call the service method
            appDelegate.serviceCorrectText(pboard, userData: nil, error: errorPtr)

            if let error = error {
                logManager.error("Service returned error: \(error)")
            }

            // Check clipboard
            if let clipboardContent = pboard.string(forType: .string) {
                logManager.info("✅ Clipboard now contains: '\(clipboardContent)'")
            }
        } else {
            logManager.error("appDelegateShared is nil! App might not be fully started yet.")
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Level icon
            Image(systemName: entry.level.icon)
                .foregroundStyle(entry.level.color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                // Timestamp and level
                HStack(spacing: 6) {
                    Text(dateFormatter.string(from: entry.timestamp))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text(entry.level.rawValue)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(entry.level.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(entry.level.color.opacity(0.15))
                        .cornerRadius(3)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("\(entry.file):\(entry.function)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Message
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.controlBackgroundColor).opacity(0.3))
        .cornerRadius(4)
    }
}

#Preview {
    DebugWindow()
}
