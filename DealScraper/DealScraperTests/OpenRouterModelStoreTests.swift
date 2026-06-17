//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Knit
import Testing
@testable import DealScraper

struct OpenRouterModelStoreTests {

    @Test func returnsDefaultWhenNothingStored() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.openRouterModelStore()

        #expect(store.model == OpenRouterModelStore.defaultModel)
    }

    @Test func persistsModelBetweenInstances() {
        let assembler = DealScraperAssembly.testing()
        let keyValueStore = assembler.resolver.pKeyValueStore()

        let store = OpenRouterModelStore(keyValueStore: keyValueStore)
        store.model = "anthropic/claude-sonnet-4"

        let reloaded = OpenRouterModelStore(keyValueStore: keyValueStore)
        #expect(reloaded.model == "anthropic/claude-sonnet-4")
    }

    @Test func clearingModelRestoresDefault() {
        let assembler = DealScraperAssembly.testing()
        let store = assembler.resolver.openRouterModelStore()

        store.model = "anthropic/claude-sonnet-4"
        store.model = ""

        #expect(store.model == OpenRouterModelStore.defaultModel)
    }
}
