//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct SettingsView: View {

    @State var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                apiKeyField(
                    title: "Google Places API Key",
                    text: $viewModel.googlePlacesAPIKey
                )
                apiKeyField(
                    title: "OpenAI API Key",
                    text: $viewModel.openAIAPIKey
                )
                apiKeyField(
                    title: "OpenRouter API Key",
                    text: $viewModel.openRouterAPIKey
                )
            } header: {
                Text("API Keys")
            } footer: {
                Text("Keys are stored securely in the keychain.")
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
        .onChange(of: viewModel.googlePlacesAPIKey) { viewModel.save() }
        .onChange(of: viewModel.openAIAPIKey) { viewModel.save() }
        .onChange(of: viewModel.openRouterAPIKey) { viewModel.save() }
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
