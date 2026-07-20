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
                TextField("Backend URL", text: $viewModel.backendURL)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Backend")
            } footer: {
                Text("Deal extraction calls this server (e.g. http://localhost:3000 or https://duskroute.com).")
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
                Text("Keys are stored securely in the keychain. OpenRouter is used for deal extraction and venue blurbs. A Markdowner API key enables higher rate limits on md.dhr.wtf.")
            }

            Section {
                TextField("Account ID", text: $viewModel.r2AccountId)
                    .textFieldStyle(.roundedBorder)
                TextField("Bucket", text: $viewModel.r2Bucket)
                    .textFieldStyle(.roundedBorder)
                TextField("Public base URL", text: $viewModel.r2PublicBaseURL)
                    .textFieldStyle(.roundedBorder)
                apiKeyField(
                    title: "Access Key ID",
                    text: $viewModel.r2AccessKeyId
                )
                apiKeyField(
                    title: "Secret Access Key",
                    text: $viewModel.r2SecretAccessKey
                )
            } header: {
                Text("Cloudflare R2")
            } footer: {
                Text("Venue hero images are uploaded to R2 when set. Access keys are stored in the keychain.")
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 480, minHeight: 420)
        .onChange(of: viewModel.backendURL) { viewModel.save() }
        .onChange(of: viewModel.googlePlacesAPIKey) { viewModel.save() }
        .onChange(of: viewModel.openRouterAPIKey) { viewModel.save() }
        .onChange(of: viewModel.markdownerAPIKey) { viewModel.save() }
        .onChange(of: viewModel.r2AccountId) { viewModel.save() }
        .onChange(of: viewModel.r2Bucket) { viewModel.save() }
        .onChange(of: viewModel.r2PublicBaseURL) { viewModel.save() }
        .onChange(of: viewModel.r2AccessKeyId) { viewModel.save() }
        .onChange(of: viewModel.r2SecretAccessKey) { viewModel.save() }
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
