//
//  AppDelegate.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import SwiftUI
import AppKit

// Global AppDelegate reference for service access
var appDelegateShared: AppDelegate?

    @objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var onboardingWindow: NSWindow?
    var debugWindow: NSWindow?
    var settingsWindow: NSWindow?
    var textCorrectService: TextCorrectService?
    let permissionChecker = PermissionChecker()
    let logger = LogManager.shared

    override init() {
        super.init()
        logger.info("AppDelegate: Init")
    }

    deinit {
        logger.info("AppDelegate: Deinit")
    }

    // Service method - MUST be in the app delegate for macOS Services to find it
    @objc func serviceCorrectText(_ pboard: NSPasteboard, userData: String?, error errorPtr: AutoreleasingUnsafeMutablePointer<NSString?>) {
        handleService(pboard, serviceType: .correction, processingMessage: "Metin düzeltiliyor...", successNotificationTitle: "Metin Düzeltildi", error: errorPtr)
    }

    @objc func serviceTranslateToEnglish(_ pboard: NSPasteboard, userData: String?, error errorPtr: AutoreleasingUnsafeMutablePointer<NSString?>) {
        handleService(pboard, serviceType: .translateToEnglish, processingMessage: "Metin İngilizce'ye çevriliyor...", successNotificationTitle: "İngilizce'ye Çevrildi", error: errorPtr)
    }

    @objc func serviceTranslateToTurkish(_ pboard: NSPasteboard, userData: String?, error errorPtr: AutoreleasingUnsafeMutablePointer<NSString?>) {
        handleService(pboard, serviceType: .translateToTurkish, processingMessage: "Metin Türkçe'ye çevriliyor...", successNotificationTitle: "Türkçe'ye Çevrildi", error: errorPtr)
    }

    private func handleService(
        _ pboard: NSPasteboard,
        serviceType: ServiceType,
        processingMessage: String,
        successNotificationTitle: String,
        error errorPtr: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        // VISUAL INDICATOR: Bounce Dock icon
        NSApp.requestUserAttention(.criticalRequest)

        logger.info("Service called: \(serviceType)")
        LogManager.shared.incrementServiceCallCount()

        // Check if API is configured
        let config = APIConfig.shared
        guard config.isConfigured else {
            logger.error("OpenAI API not configured")
            errorPtr.pointee = "OpenAI API yapılandırılmadı. Ayarlar'dan yapılandırın." as NSString
            showConfigurationRequiredNotification()
            return
        }

        // Try to read string from multiple types
        var inputString: String?
        if let str = pboard.string(forType: .string) {
            inputString = str
        } else if let str = pboard.string(forType: .init("public.utf8-plain-text")) {
             inputString = str
        } else if let str = pboard.string(forType: .init("NSStringPboardType")) {
            inputString = str
        }

        guard let text = inputString else {
            logger.error("No text found in pasteboard")
            errorPtr.pointee = "Metin bulunamadı" as NSString
            return
        }

        logger.info("Received text: '\(text)'")
        logger.info("Text length: \(text.count) characters")

        // Show "processing" indicator
        showProcessingNotification(message: processingMessage)

        // Use semaphore to wait for async API call
        let semaphore = DispatchSemaphore(value: 0)
        var resultText: String?
        var apiError: Error?

        // Process text using OpenAI API asynchronously
        Task {
            do {
                let service = OpenAIService()
                let result = try await service.processText(text, serviceType: serviceType)
                resultText = result
                logger.info("API call successful, got result text")
            } catch let err {
                logger.error("API call failed: \(err.localizedDescription)")
                apiError = err
            }
            semaphore.signal()
        }

        // Wait for the API call to complete (with timeout) - use RunLoop in multiple modes to keep UI responsive
        let timeout = DispatchTime.now() + 60
        var timedOut = false

        while semaphore.wait(timeout: .now() + 0.01) == .timedOut {
            // Check if we've exceeded the total timeout
            if DispatchTime.now() > timeout {
                timedOut = true
                break
            }
            // Process UI events in multiple modes to keep status bar responsive
            RunLoop.current.run(mode: .eventTracking, before: Date(timeIntervalSinceNow: 0.001))
            RunLoop.current.run(mode: .modalPanel, before: Date(timeIntervalSinceNow: 0.001))
        }

        if timedOut {
            logger.error("API call timed out after 60 seconds")
            errorPtr.pointee = "İstek zaman aşımına uğradı. Lütfen tekrar deneyin." as NSString
            showErrorNotification(error: "İstek zaman aşımı")
            return
        }

        // Check for errors
        if let err = apiError {
            let errorMsg = (err as? OpenAIError)?.errorDescription ?? err.localizedDescription
            logger.error("Failed to process text: \(errorMsg)")
            errorPtr.pointee = errorMsg as NSString
            showErrorNotification(error: errorMsg)
            return
        }

        guard let finalText = resultText else {
            logger.error("No result text returned")
            errorPtr.pointee = "Sonuç alınamadı" as NSString
            showErrorNotification(error: "İşlem başarısız")
            return
        }

        logger.info("Result text: '\(finalText)'")

        // IMPORTANT: Clear the pasteboard before writing back
        pboard.clearContents()

        // Write back multiple types to ensure compatibility
        var writeSuccess = false

        // Write standard string
        if pboard.setString(finalText, forType: .string) {
            writeSuccess = true
        }

        // Write public.utf8-plain-text
        if pboard.setString(finalText, forType: .init("public.utf8-plain-text")) {
             writeSuccess = true
        }

        // Write legacy NSStringPboardType
        if pboard.setString(finalText, forType: .init("NSStringPboardType")) {
             writeSuccess = true
        }

        if writeSuccess {
            logger.info("Successfully wrote corrected text back")
            // Also copy to general clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(finalText, forType: .string)
        } else {
            logger.error("Failed to write to pasteboard")
            errorPtr.pointee = "Düzeltilen metin yazılamadı" as NSString
            showErrorNotification(error: "Yazma hatası")
            return
        }

        // Show notification
        showNotification(title: successNotificationTitle, originalText: text, resultText: finalText)
    }

    private func showNotification(title: String, originalText: String, resultText: String) {
        logger.info("Showing notification: \(title)")
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = "\"\(originalText.prefix(50))...\" → \"\(resultText.prefix(50))...\""
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        logger.info("Notification delivered")
    }

    private func showProcessingNotification(message: String) {
        showNotification(title: "Text Correct", message: message, playSound: false)
    }

    private func showConfigurationRequiredNotification() {
        showNotification(
            title: "Text Correct - Yapılandırma Gerekli",
            message: "OpenAI API anahtarı gerekli. Ayarlar'dan yapılandırın.",
            playSound: true
        )
    }

    private func showErrorNotification(error: String) {
        showNotification(title: "Text Correct - Hata", message: error, playSound: true)
    }

    private func showNotification(title: String, message: String, playSound: Bool) {
        logger.info("Showing notification: \(title)")
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        if playSound {
            notification.soundName = NSUserNotificationDefaultSoundName
        }
        NSUserNotificationCenter.default.deliver(notification)
        logger.info("Notification delivered")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set global reference
        appDelegateShared = self
        logger.info("Application launched")

        // Register Services - THIS IS CRITICAL for services to work!
        logger.info("Registering Services menu")
        NSApp.registerServicesMenuSendTypes([.string, .init("public.utf8-plain-text")], returnTypes: [.string, .init("public.utf8-plain-text")])

        // EXPLICIT REGISTRATION
        logger.info("Registering service provider: text-correct")
        NSRegisterServicesProvider(self, "text-correct")

        // Initialize the service
        logger.info("Initializing TextCorrectService")
        textCorrectService = TextCorrectService()

        // Register the service with the system
        logger.info("Updating dynamic services")
        NSUpdateDynamicServices()

        // Verify service registration
        verifyServiceRegistration()

        // Set up menu bar (always, regardless of onboarding)
        setupMenuBar()

        // Check if onboarding is needed
        if permissionChecker.needsOnboarding {
            showOnboarding()
        }

        logger.info("Service method ready in AppDelegate")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application will terminate")
    }

    private func verifyServiceRegistration() {
        logger.info("Verifying service registration")

        // Check NSServices in Info.plist
        if let servicesPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: servicesPath),
           let services = plist["NSServices"] as? [NSDictionary] {
            logger.info("Found \(services.count) service(s) in Info.plist")
            for (index, service) in services.enumerated() {
                if let menuItem = service["NSMenuItem"] as? NSDictionary,
                   let defaultName = menuItem["default"] as? String {
                    logger.info("  Service \(index): \(defaultName)")
                }
                if let message = service["NSMessage"] as? String {
                    logger.info("    Handler: \(message)")
                }
            }
        } else {
            logger.error("Could not find NSServices in Info.plist")
        }

        logger.info("Service ready: Select text → Right-click → Services → ✏️ Metni Düzelt")
    }

    func setupMenuBar() {
        // Hide from Dock - only show in menu bar
        NSApp.setActivationPolicy(.accessory)
        logger.info("Activation policy: accessory (hidden from Dock)")

        // Create the status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        logger.info("Status bar item created")

        if let button = statusBarItem?.button {
            button.title = "✓ Text"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            logger.info("Status bar button configured: '✓ Text'")
        } else {
            logger.error("Status bar button is nil")
        }

        // Create right-click menu
        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()

        // Settings option
        let settingsItem = NSMenuItem(
            title: "Ayarlar",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Debug Window option
        let debugItem = NSMenuItem(
            title: "Debug Logs",
            action: #selector(toggleDebugWindow),
            keyEquivalent: "d"
        )
        debugItem.target = self
        menu.addItem(debugItem)

        menu.addItem(NSMenuItem.separator())

        // Quit option
        let quitItem = NSMenuItem(
            title: "Çıkış",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarItem?.menu = menu
        logger.info("Status bar menu configured")
    }

    @objc func toggleDebugWindow() {
        if let debugWindow = debugWindow, debugWindow.isVisible {
            debugWindow.orderOut(nil)
            logger.info("Debug window hidden")
        } else {
            showDebugWindow()
        }
    }

    @objc func quitApp() {
        logger.info("Quit requested")
        NSApp.terminate(nil)
    }

    func showOnboarding() {
        // Temporarily show in dock for onboarding
        NSApp.setActivationPolicy(.regular)

        let onboardingView = OnboardingView {
            self.onboardingCompleted()
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Text Correct - Kurulum"
        window.contentViewController = hostingController
        window.delegate = self  // Set delegate to restore menu on close
        window.makeKeyAndOrderFront(nil)

        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func onboardingCompleted() {
        onboardingWindow?.close()
        onboardingWindow = nil
        logger.info("Onboarding completed")

        // Go back to accessory mode (hide from Dock)
        NSApp.setActivationPolicy(.accessory)
        logger.info("Activation policy: accessory (hidden from Dock)")
    }

    func showDebugWindow() {
        if let debugWindow = debugWindow, debugWindow.isVisible {
            debugWindow.orderFront(nil)
            return
        }

        let debugView = DebugWindow()
        let hostingController = NSHostingController(rootView: debugView)
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Text Correct - Debug"
        window.contentViewController = hostingController
        window.setFrameAutosaveName("DebugWindow")
        window.delegate = self  // Set delegate to restore menu on close
        window.makeKeyAndOrderFront(nil)

        debugWindow = window
        logger.info("Debug window opened")
    }

    @objc func showSettings() {
        // Ensure menu is set up
        setupMenu()

        // If window exists and is visible, bring to front
        if let settingsWindow = settingsWindow, settingsWindow.isVisible {
            settingsWindow.orderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Text Correct - Ayarlar"
        window.contentViewController = hostingController
        window.delegate = self  // Set delegate to restore menu on close
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
        logger.info("Settings window opened")
    }

    // NSWindowDelegate method - called when window is about to close
    func windowWillClose(_ notification: Notification) {
        // Check which window is closing and clear its reference
        if let window = notification.object as? NSWindow {
            if window === settingsWindow {
                settingsWindow = nil
                logger.info("Settings window reference cleared")
            } else if window === debugWindow {
                debugWindow = nil
                logger.info("Debug window reference cleared")
            } else if window === onboardingWindow {
                onboardingWindow = nil
                logger.info("Onboarding window reference cleared")
            }
        }

        // Restore menu synchronously when any window closes
        // Using synchronous operation to prevent race conditions with deallocation
        setupMenu()
        logger.info("Menu restored after window close")
    }

    @objc func statusBarButtonClicked() {
        // Close menu if shown
        statusBarItem?.menu = nil

        // Show popover after a short delay to allow menu to close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if let popover = self.popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    self.showPopover()
                }
            } else {
                self.showPopover()
            }
        }

        // Restore menu synchronously - eliminate async delay to prevent race conditions
        self.setupMenu()
    }

    func showPopover() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 320, height: 180)
            popover?.behavior = .transient
            popover?.contentViewController = NSHostingController(rootView: ContentView())
        }

        if let button = statusBarItem?.button, let popover = popover {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
