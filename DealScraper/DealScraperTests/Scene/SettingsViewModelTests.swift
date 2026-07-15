//Created by Alex Skorulis on 15/6/2026.

import Knit
import Testing
@testable import DealScraper

@MainActor
struct SettingsViewModelTests {

    @Test func loadsAndSavesAPIKeys() {
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        let r2ConfigStore = assembler.resolver.r2ConfigStore()
        apiKeyStore.googlePlacesAPIKey = "google-key"
        apiKeyStore.openRouterAPIKey = "openrouter-key"
        apiKeyStore.markdownerAPIKey = "markdowner-key"
        r2ConfigStore.accountId = "acct-id"
        r2ConfigStore.accessKeyId = "access-key"
        r2ConfigStore.secretAccessKey = "secret-key"

        let viewModel = assembler.resolver.settingsViewModel()

        #expect(viewModel.googlePlacesAPIKey == "google-key")
        #expect(viewModel.openRouterAPIKey == "openrouter-key")
        #expect(viewModel.markdownerAPIKey == "markdowner-key")
        #expect(viewModel.r2AccountId == "acct-id")
        #expect(viewModel.r2AccessKeyId == "access-key")
        #expect(viewModel.r2SecretAccessKey == "secret-key")
        #expect(viewModel.r2Bucket == R2ConfigStore.defaultBucket)

        viewModel.googlePlacesAPIKey = "updated-google"
        viewModel.openRouterAPIKey = "updated-openrouter"
        viewModel.markdownerAPIKey = "updated-markdowner"
        viewModel.r2AccountId = "acct-2"
        viewModel.save()

        #expect(apiKeyStore.googlePlacesAPIKey == "updated-google")
        #expect(apiKeyStore.openRouterAPIKey == "updated-openrouter")
        #expect(apiKeyStore.markdownerAPIKey == "updated-markdowner")
        #expect(r2ConfigStore.accountId == "acct-2")
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
