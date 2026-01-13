//
//  PermissionChecker.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import AppKit
import SwiftUI

class PermissionChecker: ObservableObject {
    @Published var serviceEnabled = false
    @Published var isChecking = false
    private let onboardingKey = "hasCompletedOnboarding"

    var needsOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: onboardingKey)
    }

    init() {
        checkPermissions()
    }

    func checkPermissions() {
        isChecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.serviceEnabled = self.checkServiceEnabled()
            self.isChecking = false
            NSLog("Text Correct: Service enabled check result: \(self.serviceEnabled)")
        }
    }

    private func checkServiceEnabled() -> Bool {
        // Method 1: Check via LSServices (more reliable)
        if let services = LSServices() as? [[String: Any]] {
            for service in services {
                if let message = service["NSMessage"] as? String,
                   message == "serviceCorrectText" {
                    return true
                }
            }
        }

        // Method 2: Check the Services file directly
        let servicesPlist = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Services")
            .appendingPathComponent("TextCorrect.service")

        if FileManager.default.fileExists(atPath: servicesPlist.path) {
            return true
        }

        // Method 3: Check if the app bundle has the service registered
        let appPath = Bundle.main.bundlePath
        let infoPlist = URL(fileURLWithPath: appPath)
            .appendingPathComponent("Contents")
            .appendingPathComponent("Info.plist")

        if let dict = NSDictionary(contentsOf: infoPlist),
           let services = dict["NSServices"] as? [[String: Any]] {
            return !services.isEmpty
        }

        // Method 4: Check system services configuration
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/libexec/PlistBuddy")
        task.arguments = [
            "-c", "Print",
            "/System/Library/Services/TextCorrect.service/Contents/Info.plist"
        ]

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                return true
            }
        } catch {
            // PlistBuddy failed, try next method
        }

        // Fallback: Assume it's enabled if the app is installed
        // User will verify manually
        return false
    }

    func manuallyConfirmEnabled() {
        serviceEnabled = true
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }
}

// Helper for LSServices
private func LSServices() -> NSArray? {
    let kLSServicesKey = "NSServices"
    guard let servicesDefaults = UserDefaults.standard.persistentDomain(forName: kLSServicesKey) else {
        return nil
    }
    return servicesDefaults[kLSServicesKey] as? NSArray
}
