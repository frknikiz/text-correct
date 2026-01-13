//
//  TextCorrectService.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import AppKit

@objc(TextCorrectService)
class TextCorrectService: NSObject {
    private let logger = LogManager.shared
    private let openAIService = OpenAIService()
    private let config = APIConfig.shared

    @objc func serviceCorrectText(_ pboard: NSPasteboard, userData: String?, error errorPtr: AutoreleasingUnsafeMutablePointer<NSString?>) {
        logger.info("Service called")

        // Check if API is configured
        guard config.isConfigured else {
            logger.error("OpenAI API not configured")
            errorPtr.pointee = "OpenAI API yapılandırılmadı. Lütfen Ayarlar'dan API anahtarınızı girin." as NSString
            showConfigurationRequiredNotification()
            return
        }

        // Log pasteboard types
        let types = pboard.types ?? []
        logger.info("Pasteboard types: \(types)")

        // Ensure pasteboard contains string data
        let canRead = pboard.canReadObject(forClasses: [NSString.self], options: nil)
        logger.info("Can read string: \(canRead)")

        guard canRead, let text = pboard.string(forType: .string) else {
            logger.error("No text found in pasteboard")
            logger.error("Available types: \(types)")
            errorPtr.pointee = "Metin bulunamadı" as NSString
            return
        }

        logger.info("Received text: '\(text)'")
        logger.info("Text length: \(text.count) characters")

        // Correct text using OpenAI API
        Task {
            do {
                let correctedText = try await openAIService.correctText(text)

                await MainActor.run {
                    logger.info("Corrected text: '\(correctedText)'")

                    // Copy to clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    let writeSuccess = pasteboard.setString(correctedText, forType: .string)
                    logger.info("Clipboard write: \(writeSuccess)")

                    if writeSuccess {
                        // Verify clipboard content
                        if let clipboardContent = pasteboard.string(forType: .string) {
                            logger.info("Verified clipboard: '\(clipboardContent)'")
                        } else {
                            logger.error("Clipboard verification failed")
                        }
                    }

                    // Write back to pasteboard for service replacement
                    pboard.clearContents()
                    let serviceWriteSuccess = pboard.setString(correctedText, forType: .string)
                    logger.info("Service pasteboard write: \(serviceWriteSuccess)")

                    logger.info("Service completed")

                    // Show a brief notification
                    showNotification(text: text, correctedText: correctedText)
                }
            } catch let err {
                await MainActor.run {
                    logger.error("Failed to correct text: \(err.localizedDescription)")
                    let errorMsg = (err as? OpenAIError)?.errorDescription ?? err.localizedDescription
                    errorPtr.pointee = errorMsg as NSString
                    showErrorNotification(error: errorMsg)
                }
            }
        }
    }

    private func showNotification(text: String, correctedText: String) {
        logger.info("Showing notification")
        let notification = NSUserNotification()
        notification.title = "Metin Düzeltildi"
        notification.informativeText = "\"\(text.prefix(50))...\" → \"\(correctedText.prefix(50))...\""
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        logger.info("Notification delivered")
    }

    private func showConfigurationRequiredNotification() {
        let notification = NSUserNotification()
        notification.title = "Text Correct - Yapılandırma Gerekli"
        notification.informativeText = "OpenAI API anahtarı gerekli. Ayarlar'dan yapılandırın."
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }

    private func showErrorNotification(error: String) {
        let notification = NSUserNotification()
        notification.title = "Text Correct - Hata"
        notification.informativeText = error
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
