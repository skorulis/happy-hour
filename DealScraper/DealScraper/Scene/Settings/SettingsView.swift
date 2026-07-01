//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct SettingsView: View {

    @State var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Button {
                    viewModel.showStats()
                } label: {
                    Label("Stats", systemImage: "chart.bar")
                }
            }

            Section {
                apiKeyField(
                    title: "Google Places API Key",
                    text: $viewModel.googlePlacesAPIKey
                )
                apiKeyField(
                    title: "OpenRouter API Key",
                    text: $viewModel.openRouterAPIKey
                )
                apiKeyField(
                    title: "Markdowner API Key",
                    text: $viewModel.markdownerAPIKey
                )
            } header: {
                Text("API Keys")
            } footer: {
                Text("Keys are stored securely in the keychain. A Markdowner API key enables higher rate limits on md.dhr.wtf.")
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
        .onChange(of: viewModel.googlePlacesAPIKey) { viewModel.save() }
        .onChange(of: viewModel.openRouterAPIKey) { viewModel.save() }
        .onChange(of: viewModel.markdownerAPIKey) { viewModel.save() }
    }

    private func apiKeyField(title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textFieldStyle(.roundedBorder)
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    SettingsView(viewModel: assembler.resolver.settingsViewModel())
}
