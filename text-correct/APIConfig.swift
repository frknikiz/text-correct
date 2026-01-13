//
//  APIConfig.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import Foundation

enum ServiceType {
    case correction
    case translateToEnglish
    case translateToTurkish
}

class APIConfig: ObservableObject {
    static let shared = APIConfig()

    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: Keys.apiKey)
        }
    }

    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: Keys.baseURL)
        }
    }

    @Published var model: String {
        didSet {
            UserDefaults.standard.set(model, forKey: Keys.model)
        }
    }

    private struct Keys {
        static let apiKey = "openai_api_key"
        static let baseURL = "openai_base_url"
        static let model = "openai_model"
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        self.baseURL = UserDefaults.standard.string(forKey: Keys.baseURL) ?? "https://api.openai.com/v1"
        self.model = UserDefaults.standard.string(forKey: Keys.model) ?? "gpt-4o-mini"
    }

    func clearCredentials() {
        apiKey = ""
        baseURL = "https://api.openai.com/v1"
        UserDefaults.standard.removeObject(forKey: Keys.apiKey)
        UserDefaults.standard.removeObject(forKey: Keys.baseURL)
        UserDefaults.standard.removeObject(forKey: Keys.model)
    }

    // MARK: - Prompt Template Builder

    private struct PromptTemplate {
        let role: String
        let rules: [String]
        let targetLanguage: String
        let jsonKey: String = "result"

        func buildPrompt() -> String {
            let rulesText = rules.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let examples = buildExamples()

            return """
            Sen bir \(role). Görevin verilen metni işlemek.

            ÇOK ÖNEMLİ KURALLAR:
            \(rulesText)

            ZORUNLU JSON FORMATI:
            {"\(jsonKey)": "buraya sonucu yaz"}

            \(examples)

            ŞİMDİ METNİ İŞLE VE SADECE JSON DÖNDÜR:
            """
        }

        private func buildExamples() -> String {
            switch role {
            case let r where r.contains("düzeltme"):
                return """
                ÖRNEKLER:
                Girdi: "merhaba nasılsın iyimisin"
                Cevap: {"\(jsonKey)": "Merhaba, nasılsın? İy misin?"}

                Girdi: "bugün hava çok guzel arkadaslarla parka gittik"
                Cevap: {"\(jsonKey)": "Bugün hava çok güzel. Arkadaşlarla parka gittik."}
                """
            case let r where r.contains("İngilizceye"):
                return """
                ÖRNEKLER:
                Girdi: "Merhaba, nasılsın?"
                Cevap: {"\(jsonKey)": "Hello, how are you?"}

                Girdi: "Bugün hava çok güzel."
                Cevap: {"\(jsonKey)": "The weather is very beautiful today."}
                """
            case let r where r.contains("Türkçeye"):
                return """
                ÖRNEKLER:
                Girdi: "Hello, how are you?"
                Cevap: {"\(jsonKey)": "Merhaba, nasılsın?"}

                Girdi: "The weather is beautiful today."
                Cevap: {"\(jsonKey)": "Bugün hava çok güzel."}
                """
            default:
                return ""
            }
        }
    }

    private func getCorrectionPrompt() -> String {
        let template = PromptTemplate(
            role: "Türkçe metin düzeltme uzmanısın. Görevin verilen metindeki sadece şu hataları düzeltmek: noktalama, imla, kelime ve büyük/küçük harf hataları",
            rules: [
                "Metnin orijinal yapısını KORU - paragraf yapısı, satır sonları bozulmamalı",
                "Anlamı değiştirme - sadece yukarıdaki hataları düzelt",
                "Cevap MUTLAKA Türkçe olmalı",
                "Cevap MUTLAKA JSON formatında olmalı, başka hiçbir şey ekleme"
            ],
            targetLanguage: "Turkish"
        )
        return template.buildPrompt()
    }

    private func getTranslateToEnglishPrompt() -> String {
        let template = PromptTemplate(
            role: "Türkçeden İngilizceye çevirmenisin. Görevin verilen Türkçe metni İngilizceye çevirmek",
            rules: [
                "Metnin orijinal yapısını KORU - paragraf yapısı, satır sonları bozulmamalı",
                "Sadece çeviri yap, anlamı değiştirme veya ekleme yapma",
                "Cevap MUTLAKA İngilizce olmalı",
                "Cevap MUTLAKA JSON formatında olmalı, başka hiçbir şey ekleme"
            ],
            targetLanguage: "English"
        )
        return template.buildPrompt()
    }

    private func getTranslateToTurkishPrompt() -> String {
        let template = PromptTemplate(
            role: "İngilizceden Türkçeye çevirmenisin. Görevin verilen İngilizce metni Türkçeye çevirmek",
            rules: [
                "Metnin orijinal yapısını KORU - paragraf yapısı, satır sonları bozulmamalı",
                "Sadece çeviri yap, anlamı değiştirme veya ekleme yapma",
                "Cevap MUTLAKA Türkçe olmalı",
                "Cevap MUTLAKA JSON formatında olmalı, başka hiçbir şey ekleme"
            ],
            targetLanguage: "Turkish"
        )
        return template.buildPrompt()
    }

    func getSystemPrompt(for type: ServiceType) -> String {
        switch type {
        case .correction:
            return getCorrectionPrompt()
        case .translateToEnglish:
            return getTranslateToEnglishPrompt()
        case .translateToTurkish:
            return getTranslateToTurkishPrompt()
        }
    }

    func getSystemPrompt() -> String {
        return getCorrectionPrompt()
    }
}
