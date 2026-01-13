//
//  ContentView.swift
//  text-correct
//
//  Created by frkn on 10.01.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "text.spell")
                    .font(.title)
                    .foregroundColor(.accentColor)
                Text("Text Correct")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Durum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Aktif")
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Kullanım")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Herhangi bir metni seçin ve sağ tıklayın → Services")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Text("  ✏️ Metni Düzelt - Türkçe metin düzeltme")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("  🇬🇧 İngilizce'ye Çevir - TR→EN çeviri")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("  🇹🇷 Türkçe'ye Çevir - EN→TR çeviri")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Sürüm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("v1.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(width: 320, height: 180)
    }
}

#Preview {
    ContentView()
}
