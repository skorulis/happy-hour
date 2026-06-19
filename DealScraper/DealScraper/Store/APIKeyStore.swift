//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

final class APIKeyStore {

    private enum Key {
        static let googlePlaces = "googlePlacesAPIKey"
        static let openRouter = "openRouterAPIKey"
        static let markdowner = "markdownerAPIKey"
    }

    private let secureStore: SecureKeyValueStore

    init(secureStore: SecureKeyValueStore) {
        self.secureStore = secureStore
    }

    var googlePlacesAPIKey: String {
        get { secureStore.string(forKey: Key.googlePlaces) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.googlePlaces) }
    }

    var openRouterAPIKey: String {
        get { secureStore.string(forKey: Key.openRouter) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.openRouter) }
    }

    var markdownerAPIKey: String {
        get { secureStore.string(forKey: Key.markdowner) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: Key.markdowner) }
    }
}
