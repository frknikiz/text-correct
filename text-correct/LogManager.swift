//
//  LogManager.swift
//  text-correct
//
//  Created by Claude on 10.01.2026.
//

import Foundation
import SwiftUI
import os.log

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var serviceCallCount: Int = 0
    private let logger = Logger(subsystem: "frkn.text-correct", category: "Debug")
    private let maxLogs = 500

    private init() {
    }

    deinit {
    }

    func incrementServiceCallCount() {
        DispatchQueue.main.async {
            self.serviceCallCount += 1
        }
    }

    func log(_ message: String, level: LogLevel = .info, function: String = #function, file: String = #file) {
        let timestamp = Date()
        let filename = (file as NSString).lastPathComponent
        let entry = LogEntry(
            timestamp: timestamp,
            level: level,
            message: message,
            function: function,
            file: filename
        )

        DispatchQueue.main.async {
            self.logs.append(entry)
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst()
            }
        }

        // Also log to system logger
        let logMessage = "[\(level.rawValue)] \(message)"
        switch level {
        case .debug:
            self.logger.debug("\(logMessage)")
        case .info:
            self.logger.info("\(logMessage)")
        case .warning:
            self.logger.warning("\(logMessage)")
        case .error:
            self.logger.error("\(logMessage)")
        }

        // Print to console for immediate visibility
        print("[\(timestampFormatter.string(from: timestamp))] [\(level.rawValue.uppercased())] \(message)")
    }

    func debug(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .debug, function: function, file: file)
    }

    func info(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .info, function: function, file: file)
    }

    func warning(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .warning, function: function, file: file)
    }

    func error(_ message: String, function: String = #function, file: String = #file) {
        log(message, level: .error, function: function, file: file)
    }

    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
        info("Logs cleared")
    }

    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let function: String
    let file: String
}

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    var color: Color {
        switch self {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    var icon: String {
        switch self {
        case .debug: return "ladybug"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}
