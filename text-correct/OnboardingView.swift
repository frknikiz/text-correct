//
//  OnboardingView.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void = {}
    @StateObject private var permissionChecker = PermissionChecker()
    @StateObject private var config = APIConfig.shared
    @State private var currentPage = 0

    // API Key input states
    @State private var apiKey: String = ""
    @State private var baseURL: String = "https://api.openai.com/v1"
    @State private var model: String = "gpt-4o-mini"
    @State private var isTestingConnection = false
    @State private var apiTestResult: APITestResult?
    @State private var showingAPIError = false
    @State private var apiErrorMessage = ""

    enum APITestResult {
        case success
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 8) {
                HStack {
                    Text("Text Correct - Kurulum")
                        .font(.headline)
                    Spacer()
                }

                HStack {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index <= currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    switch currentPage {
                    case 0:
                        welcomePage
                    case 1:
                        apiConfigPage
                    case 2:
                        permissionsPage
                    case 3:
                        readyPage
                    default:
                        EmptyView()
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }

            Divider()

            // Navigation buttons - always visible
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button("Geri") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }

                Spacer()

                if currentPage == 2 {
                    Button("Etkinleştirdim") {
                        permissionChecker.manuallyConfirmEnabled()
                    }
                    .buttonStyle(.bordered)
                    .disabled(permissionChecker.serviceEnabled)
                }

                Button(currentPage == 3 ? "Bitir" : "İleri") {
                    if currentPage == 1 {
                        // Save API config before proceeding
                        saveAPIConfig()
                    }
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        permissionChecker.completeOnboarding()
                        onComplete()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentPage == 1 && !isAPIConfigValid())
                .disabled(currentPage == 2 && !permissionChecker.serviceEnabled)
                .keyboardShortcut(.rightArrow, modifiers: [])
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 550, height: 500)
        .onAppear {
            permissionChecker.checkPermissions()
        }
        .alert("API Hatası", isPresented: $showingAPIError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(apiErrorMessage)
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.spell")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Text Correct")
                .font(.title)
                .fontWeight(.bold)

            Text("Metin düzeltme ve çeviri için sistem entegrasyonlu hizmet.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "doc.text", text: "Herhangi bir uygulamada metin seçin")
                FeatureRow(icon: "arrow.turn.down.right", text: "Sağ tıklayın → Services")
                FeatureRow(icon: "checkmark.circle", text: "Metin düzeltilir veya çevrilir")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Mevcut Hizmetler:")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("✏️ Metni Düzelt - Türkçe metin düzeltme")
                    .font(.caption2)
                Text("🇬🇧 İngilizce'ye Çevir - Türkçeden İngilizceye")
                    .font(.caption2)
                Text("🇹🇷 Türkçe'ye Çevir - İngilizceden Türkçeye")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    private var permissionsPage: some View {
        VStack(spacing: 20) {
            Image(systemName: permissionChecker.serviceEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(permissionChecker.serviceEnabled ? .green : .orange)

            Text("Services Hizmeti Etkinleştirme")
                .font(.title2)
                .fontWeight(.semibold)

            if !permissionChecker.serviceEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kurulum adımları:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    StepRow(number: "1", text: "System Settings (Ayarlar) açın")
                    StepRow(number: "2", text: "Keyboard → Keyboard Shortcuts → Services")
                    StepRow(number: "3", text: "Text kısmında tüm hizmetleri işaretleyin:")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("  • Metni Düzelt")
                            .font(.caption2)
                        Text("  • İngilizce'ye Çevir")
                            .font(.caption2)
                        Text("  • Türkçe'ye Çevir")
                            .font(.caption2)
                    }
                    .padding(.leading, 16)
                    StepRow(number: "4", text: "Aşağıdaki 'Etkinleştirdim' butonuna tıklayın")

                    Button("System Settings'i Aç") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Services")!)
                    }
                    .buttonStyle(.link)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            PermissionStatusRow(
                title: "Services Hizmeti",
                isEnabled: permissionChecker.serviceEnabled
            )
        }
    }

    private var apiConfigPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("API Yapılandırması")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Metin düzeltme için OpenAI uyumlu API kullanacağız. API anahtarınızı girin.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Anahtarı")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiKey) { _ in
                            apiTestResult = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Base URL (İsteğe bağlı)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("https://api.openai.com/v1", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Model (İsteğe bağlı)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("gpt-4o-mini", text: $model)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 12) {
                    Button(isTestingConnection ? "Test ediliyor..." : "Bağlantıyı Test Et") {
                        Task {
                            await testAPIConnection()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTestingConnection || apiKey.isEmpty)

                    if isTestingConnection {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    if let apiTestResult = apiTestResult {
                        switch apiTestResult {
                        case .success:
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Başarılı")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        case .failure(let message):
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI Uyumlu API'ler:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("OpenAI, Anthropic, Groq, DeepSeek vb.")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var readyPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Kurulum Tamamlandı")
                .font(.title)
                .fontWeight(.bold)

            Text("Uygulama kullanıma hazır.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                StatusRow(icon: "menubar.rectangle", text: "Menü çubuğunda '✓ Text' simgesi görünür")
                StatusRow(icon: "text.cursor", text: "Services menüsünde 3 hizmet aktif")
                StatusRow(icon: "doc.on.doc", text: "Metin düzeltebilir veya çevirebilirsiniz")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Functions

    private func isAPIConfigValid() -> Bool {
        !apiKey.isEmpty && apiTestResult != nil
    }

    private func saveAPIConfig() {
        config.apiKey = apiKey
        config.baseURL = baseURL.isEmpty ? "https://api.openai.com/v1" : baseURL
        config.model = model.isEmpty ? "gpt-4o-mini" : model
    }

    private func testAPIConnection() async {
        isTestingConnection = true
        apiTestResult = nil

        // Save temporary config for testing
        let tempBaseURL = baseURL.isEmpty ? "https://api.openai.com/v1" : baseURL
        let tempModel = model.isEmpty ? "gpt-4o-mini" : model

        config.apiKey = apiKey
        config.baseURL = tempBaseURL
        config.model = tempModel

        let service = OpenAIService()

        do {
            try await service.testConnection()
            apiTestResult = .success
        } catch {
            let errorMsg = (error as? OpenAIError)?.errorDescription ?? error.localizedDescription
            apiTestResult = .failure(errorMsg)
            apiErrorMessage = errorMsg
            showingAPIError = true
        }

        isTestingConnection = false
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct PermissionStatusRow: View {
    let title: String
    let isEnabled: Bool

    var body: some View {
        HStack {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isEnabled ? .green : .red)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(isEnabled ? "Etkin" : "Etkin Değil")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEnabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

struct StatusRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    OnboardingView()
}
