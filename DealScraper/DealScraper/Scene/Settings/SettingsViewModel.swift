//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SettingsViewModel {

    var googlePlacesAPIKey: String = ""
    var openAIAPIKey: String = ""
    var openRouterAPIKey: String = ""
    var cursorAPIKey: String = ""

    private let apiKeyStore: APIKeyStore

    @Resolvable<Resolver>
    init(apiKeyStore: APIKeyStore) {
        self.apiKeyStore = apiKeyStore
        load()
    }

    func load() {
        googlePlacesAPIKey = apiKeyStore.googlePlacesAPIKey
        openAIAPIKey = apiKeyStore.openAIAPIKey
        openRouterAPIKey = apiKeyStore.openRouterAPIKey
        cursorAPIKey = apiKeyStore.cursorAPIKey
    }

    func save() {
        apiKeyStore.googlePlacesAPIKey = googlePlacesAPIKey
        apiKeyStore.openAIAPIKey = openAIAPIKey
        apiKeyStore.openRouterAPIKey = openRouterAPIKey
        apiKeyStore.cursorAPIKey = cursorAPIKey
    }
}
