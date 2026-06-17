//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

final class APIKeyStore {

    private enum Key {
        static let googlePlaces = "googlePlacesAPIKey"
        static let openAI = "openAIAPIKey"
        static let openRouter = "openRouterAPIKey"
        static let cursor = "cursorAPIKey"
    }

    private let secureStore: SecureKeyValueStore

    init(secureStore: SecureKeyValueStore) {
        self.secureStore = secureStore
    }

    var googlePlacesAPIKey: String {
        get { secureStore.string(forKey: Key.googlePlaces) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.googlePlaces) }
    }

    var openAIAPIKey: String {
        get { secureStore.string(forKey: Key.openAI) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.openAI) }
    }

    var openRouterAPIKey: String {
        get { secureStore.string(forKey: Key.openRouter) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.openRouter) }
    }

    var cursorAPIKey: String {
        get { secureStore.string(forKey: Key.cursor) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.cursor) }
    }
}
