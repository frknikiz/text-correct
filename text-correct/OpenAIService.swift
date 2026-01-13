//
//  OpenAIService.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import Foundation

struct OpenAIResponse: Codable {
    let choices: [Choice]
    let error: ErrorResponse?

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }

    struct ErrorResponse: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

struct CorrectionResponse: Codable {
    let corrected_text: String
}

class OpenAIService {
    private let config = APIConfig.shared
    private let logger = LogManager.shared

    func correctText(_ text: String) async throws -> String {
        guard config.isConfigured else {
            throw OpenAIError.notConfigured
        }

        guard !text.isEmpty else {
            throw OpenAIError.emptyInput
        }

        let urlString = "\(config.baseURL)/chat/completions"
        guard let url = URL(string: urlString) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Combine system prompt with user text for better results
        let fullPrompt = config.getSystemPrompt() + "\n\n" + text

        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "user", "content": fullPrompt]
            ],
            "temperature": 0.1,  // Lower temperature for more consistent results
            "max_tokens": 4000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        logger.info("Sending request to API: \(config.baseURL)")
        logger.info("Model: \(config.model)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        logger.info("Received response with status code: \(httpResponse.statusCode)")

        // Log raw response for debugging
        if let rawResponse = String(data: data, encoding: .utf8) {
            logger.info("Raw API response: \(rawResponse.prefix(500))")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            guard let content = decodedResponse.choices.first?.message.content else {
                throw OpenAIError.noContent
            }

            logger.info("AI response content: \(content.prefix(200))")

            // Extract JSON from the response - handle various formats
            var jsonString = content
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Remove markdown code blocks if present
            if jsonString.hasPrefix("```") {
                jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            logger.info("Extracted JSON string: \(jsonString.prefix(200))")

            guard let jsonData = jsonString.data(using: .utf8) else {
                logger.error("Failed to convert JSON string to data")
                throw OpenAIError.decodingFailed
            }

            let correctionResponse = try JSONDecoder().decode(CorrectionResponse.self, from: jsonData)
            logger.info("Successfully decoded corrected text")
            return correctionResponse.corrected_text

        case 401:
            logger.error("Unauthorized - check API key")
            throw OpenAIError.unauthorized
        case 429:
            logger.error("Rate limit exceeded")
            throw OpenAIError.rateLimitExceeded
        case 500...599:
            logger.error("Server error")
            throw OpenAIError.serverError
        default:
            // Try to get error message from response
            if let rawResponse = String(data: data, encoding: .utf8) {
                logger.error("Error response: \(rawResponse)")
            }
            if let decodedResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
               let error = decodedResponse.error {
                throw OpenAIError.apiError(error.message)
            }
            throw OpenAIError.unknownError
        }
    }

    func testConnection() async throws {
        let testText = "Bu bir deneme metnidir."
        _ = try await correctText(testText)
    }
}

enum OpenAIError: LocalizedError {
    case notConfigured
    case emptyInput
    case invalidURL
    case invalidResponse
    case noContent
    case decodingFailed
    case unauthorized
    case rateLimitExceeded
    case serverError
    case apiError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI API anahtarı yapılandırılmadı"
        case .emptyInput:
            return "Düzeltilecek metin boş"
        case .invalidURL:
            return "Geçersiz API URL'si"
        case .invalidResponse:
            return "Geçersiz API yanıtı"
        case .noContent:
            return "API yanıtında içerik bulunamadı"
        case .decodingFailed:
            return "JSON çözümleme hatası"
        case .unauthorized:
            return "API anahtarı geçersiz veya yetkisiz"
        case .rateLimitExceeded:
            return "API istek limiti aşıldı"
        case .serverError:
            return "API sunucu hatası"
        case .apiError(let message):
            return "API hatası: \(message)"
        case .unknownError:
            return "Bilinmeyen bir hata oluştu"
        }
    }
}
