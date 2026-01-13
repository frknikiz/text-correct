//
//  SettingsView.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var config = APIConfig.shared
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var model: String = ""
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Ayarlar")
                    .font(.headline)
                Spacer()
                Button("Kapat") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    apiConfigSection
                    testConnectionSection
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                if let testResult = testResult {
                    switch testResult {
                    case .success:
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Bağlantı başarılı")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    case .failure(let message):
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 450, height: 400)
        .onAppear {
            loadConfig()
        }
    }

    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenAI Uyumlu API Yapılandırması")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("API Anahtarı")
                    .font(.subheadline)
                    .fontWeight(.medium)
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Base URL")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("https://api.openai.com/v1", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("gpt-4o-mini", text: $model)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                Button("Kaydet") {
                    saveConfig()
                }
                .buttonStyle(.borderedProminent)

                Button("Temizle") {
                    clearConfig()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var testConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bağlantı Testi")
                .font(.title3)
                .fontWeight(.semibold)

            Text("API yapılandırmasını test etmek için aşağıdaki butonu kullanın.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(isTestingConnection ? "Test ediliyor..." : "Bağlantıyı Test Et") {
                    Task {
                        await testConnection()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isTestingConnection || apiKey.isEmpty)

                if isTestingConnection {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func loadConfig() {
        apiKey = config.apiKey
        baseURL = config.baseURL
        model = config.model
    }

    private func saveConfig() {
        config.apiKey = apiKey
        config.baseURL = baseURL.isEmpty ? "https://api.openai.com/v1" : baseURL
        config.model = model.isEmpty ? "gpt-4o-mini" : model
        testResult = nil
    }

    private func clearConfig() {
        apiKey = ""
        baseURL = "https://api.openai.com/v1"
        model = "gpt-4o-mini"
        config.clearCredentials()
        testResult = nil
    }

    private func testConnection() async {
        isTestingConnection = true
        testResult = nil

        config.apiKey = apiKey
        config.baseURL = baseURL.isEmpty ? "https://api.openai.com/v1" : baseURL
        config.model = model.isEmpty ? "gpt-4o-mini" : model

        let service = OpenAIService()

        do {
            try await service.testConnection()
            testResult = .success
        } catch {
            let errorMsg = (error as? OpenAIError)?.errorDescription ?? error.localizedDescription
            testResult = .failure(errorMsg)
        }

        isTestingConnection = false
    }

    private func closeWindow() {
        // Close window immediately to avoid race conditions with deallocation
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}

#Preview {
    SettingsView()
}
