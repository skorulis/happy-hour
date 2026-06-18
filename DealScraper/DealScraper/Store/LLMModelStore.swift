//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

final class LLMModelStore {

    static let defaultOpenAIModel = "gpt-4o"
    static let defaultOpenRouterModel = "google/gemini-2.5-pro"

    private static let openAIKey = "dealScraper.openAIModel"
    private static let openRouterKey = "dealScraper.openRouterModel"

    private let keyValueStore: PKeyValueStore

    init(keyValueStore: PKeyValueStore) {
        self.keyValueStore = keyValueStore
    }

    var openAIModel: String {
        get { storedModel(forKey: Self.openAIKey, default: Self.defaultOpenAIModel) }
        set { storeModel(newValue, forKey: Self.openAIKey) }
    }

    var openRouterModel: String {
        get { storedModel(forKey: Self.openRouterKey, default: Self.defaultOpenRouterModel) }
        set { storeModel(newValue, forKey: Self.openRouterKey) }
    }

    private func storedModel(forKey key: String, default defaultValue: String) -> String {
        let stored = keyValueStore.string(forKey: key) ?? ""
        return stored.isEmpty ? defaultValue : stored
    }

    private func storeModel(_ value: String, forKey key: String) {
        if value.isEmpty {
            keyValueStore.removeObject(forKey: key)
        } else {
            keyValueStore.set(value, forKey: key)
        }
    }
}
