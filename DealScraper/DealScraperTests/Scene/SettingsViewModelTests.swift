//Created by Alex Skorulis on 15/6/2026.

import Knit
import Testing
@testable import DealScraper

@MainActor
struct SettingsViewModelTests {

    @Test func loadsAndSavesAPIKeys() {
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-key"
        apiKeyStore.openRouterAPIKey = "openrouter-key"
        apiKeyStore.markdownerAPIKey = "markdowner-key"

        let viewModel = assembler.resolver.settingsViewModel()

        #expect(viewModel.googlePlacesAPIKey == "google-key")
        #expect(viewModel.openRouterAPIKey == "openrouter-key")
        #expect(viewModel.markdownerAPIKey == "markdowner-key")

        viewModel.googlePlacesAPIKey = "updated-google"
        viewModel.openRouterAPIKey = "updated-openrouter"
        viewModel.markdownerAPIKey = "updated-markdowner"
        viewModel.save()

        #expect(apiKeyStore.googlePlacesAPIKey == "updated-google")
        #expect(apiKeyStore.openRouterAPIKey == "updated-openrouter")
        #expect(apiKeyStore.markdownerAPIKey == "updated-markdowner")
    }

    @Test func clearingKeyRemovesStoredValue() {
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        let viewModel = assembler.resolver.settingsViewModel()

        viewModel.openRouterAPIKey = "temporary-key"
        viewModel.save()
        #expect(apiKeyStore.openRouterAPIKey == "temporary-key")

        viewModel.openRouterAPIKey = ""
        viewModel.save()
        #expect(apiKeyStore.openRouterAPIKey == "")
    }
}
