//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Knit
import Testing
@testable import DealScraper

@MainActor
struct LLMModelStoreTests {

    @Test func returnsDefaultsWhenNothingStored() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.llmModelStore()

        #expect(store.openRouterModel == LLMModelStore.defaultOpenRouterModel)
    }

    @Test func persistsOpenRouterModelBetweenInstances() {
        let assembler = DealScraperAssembly.testing()
        let keyValueStore = assembler.resolver.pKeyValueStore()

        let store = LLMModelStore(keyValueStore: keyValueStore)
        store.openRouterModel = "anthropic/claude-sonnet-4"

        let reloaded = LLMModelStore(keyValueStore: keyValueStore)
        #expect(reloaded.openRouterModel == "anthropic/claude-sonnet-4")
    }

    @Test func clearingOpenRouterModelRestoresDefault() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.llmModelStore()

        store.openRouterModel = "anthropic/claude-sonnet-4"
        store.openRouterModel = ""

        #expect(store.openRouterModel == LLMModelStore.defaultOpenRouterModel)
    }
}
