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

        #expect(store.openAIModel == LLMModelStore.defaultOpenAIModel)
        #expect(store.openRouterModel == LLMModelStore.defaultOpenRouterModel)
    }

    @Test func persistsOpenAIModelBetweenInstances() {
        let assembler = DealScraperAssembly.testing()
        let keyValueStore = assembler.resolver.pKeyValueStore()

        let store = LLMModelStore(keyValueStore: keyValueStore)
        store.openAIModel = "gpt-4.1"

        let reloaded = LLMModelStore(keyValueStore: keyValueStore)
        #expect(reloaded.openAIModel == "gpt-4.1")
    }

    @Test func persistsOpenRouterModelBetweenInstances() {
        let assembler = DealScraperAssembly.testing()
        let keyValueStore = assembler.resolver.pKeyValueStore()

        let store = LLMModelStore(keyValueStore: keyValueStore)
        store.openRouterModel = "anthropic/claude-sonnet-4"

        let reloaded = LLMModelStore(keyValueStore: keyValueStore)
        #expect(reloaded.openRouterModel == "anthropic/claude-sonnet-4")
    }

    @Test func clearingOpenAIModelRestoresDefault() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.llmModelStore()

        store.openAIModel = "gpt-4.1"
        store.openAIModel = ""

        #expect(store.openAIModel == LLMModelStore.defaultOpenAIModel)
    }

    @Test func clearingOpenRouterModelRestoresDefault() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.llmModelStore()

        store.openRouterModel = "anthropic/claude-sonnet-4"
        store.openRouterModel = ""

        #expect(store.openRouterModel == LLMModelStore.defaultOpenRouterModel)
    }
}
