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
    }

    func save() {
        apiKeyStore.googlePlacesAPIKey = googlePlacesAPIKey
        apiKeyStore.openAIAPIKey = openAIAPIKey
        apiKeyStore.openRouterAPIKey = openRouterAPIKey
    }
}
