//
//  APIConfig.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import Foundation

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

    func getSystemPrompt() -> String {
        return """
        Sen bir Türkçe metin düzeltme uzmanısın. Görevin verilen metindeki sadece şu hataları düzeltmek:
        - Noktalama hataları (virgül, nokta, noktalı virgül, soru işareti, ünlem işareti)
        - İmla hataları (yazım yanlışları)
        - Kelime hataları (yanlış kelime kullanımları)
        - Büyük/küçük harf hataları (cümlenin başı, özel isimler)

        ÇOK ÖNEMLİ KURALLAR:
        1. Metnin orijinal yapısını KORU - paragraf yapısı, satır sonları bozulmamalı
        2. Anlamı değiştirme - sadece yukarıdaki hataları düzelt
        3. Cevap MUTLAKA Türkçe olmalı
        4. Cevap MUTLAKA JSON formatında olmalı, başka hiçbir şey ekleme

        ZORUNLU JSON FORMATI:
        {"corrected_text": "buraya düzeltilmiş metni yaz"}

        ÖRNEKLER:
        Girdi: "merhaba nasılsın iyimisin"
        Cevap: {"corrected_text": "Merhaba, nasılsın? İy misin?"}

        Girdi: "bugün hava çok guzel arkadaslarla parka gittik"
        Cevap: {"corrected_text": "Bugün hava çok güzel. Arkadaşlarla parka gittik."}

        Girdi: "ankaraya taşınacazım yeni işim yüzünden"
        Cevap: {"corrected_text": "Ankara'ya taşınacağım, yeni işim yüzünden."}

        ŞİMDİ KULLANICININ METNİNİ DÜZELT VE SADECE JSON DÖNDÜR:
        """
    }
}
