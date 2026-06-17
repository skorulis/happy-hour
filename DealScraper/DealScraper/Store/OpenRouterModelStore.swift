//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

final class OpenRouterModelStore {

    static let defaultModel = "google/gemini-2.5-pro"

    private static let key = "dealScraper.openRouterModel"

    private let keyValueStore: PKeyValueStore

    init(keyValueStore: PKeyValueStore) {
        self.keyValueStore = keyValueStore
    }

    var model: String {
        get {
            let stored = keyValueStore.string(forKey: Self.key) ?? ""
            return stored.isEmpty ? Self.defaultModel : stored
        }
        set {
            if newValue.isEmpty {
                keyValueStore.removeObject(forKey: Self.key)
            } else {
                keyValueStore.set(newValue, forKey: Self.key)
            }
        }
    }
}
