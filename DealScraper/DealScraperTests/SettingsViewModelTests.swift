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
        apiKeyStore.openAIAPIKey = "openai-key"
        apiKeyStore.openRouterAPIKey = "openrouter-key"
        apiKeyStore.cursorAPIKey = "cursor-key"

        let viewModel = assembler.resolver.settingsViewModel()

        #expect(viewModel.googlePlacesAPIKey == "google-key")
        #expect(viewModel.openAIAPIKey == "openai-key")
        #expect(viewModel.openRouterAPIKey == "openrouter-key")
        #expect(viewModel.cursorAPIKey == "cursor-key")

        viewModel.googlePlacesAPIKey = "updated-google"
        viewModel.openAIAPIKey = "updated-openai"
        viewModel.openRouterAPIKey = "updated-openrouter"
        viewModel.cursorAPIKey = "updated-cursor"
        viewModel.save()

        #expect(apiKeyStore.googlePlacesAPIKey == "updated-google")
        #expect(apiKeyStore.openAIAPIKey == "updated-openai")
        #expect(apiKeyStore.openRouterAPIKey == "updated-openrouter")
        #expect(apiKeyStore.cursorAPIKey == "updated-cursor")
    }

    @Test func clearingKeyRemovesStoredValue() {
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        let viewModel = assembler.resolver.settingsViewModel()

        viewModel.openAIAPIKey = "temporary-key"
        viewModel.save()
        #expect(apiKeyStore.openAIAPIKey == "temporary-key")

        viewModel.openAIAPIKey = ""
        viewModel.save()
        #expect(apiKeyStore.openAIAPIKey == "")
    }
}
