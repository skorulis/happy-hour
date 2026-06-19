//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SettingsViewModel {

    var googlePlacesAPIKey: String = ""
    var openRouterAPIKey: String = ""
    var markdownerAPIKey: String = ""

    private let apiKeyStore: APIKeyStore

    @Resolvable<Resolver>
    init(apiKeyStore: APIKeyStore) {
        self.apiKeyStore = apiKeyStore
        load()
    }

    func load() {
        googlePlacesAPIKey = apiKeyStore.googlePlacesAPIKey
        openRouterAPIKey = apiKeyStore.openRouterAPIKey
        markdownerAPIKey = apiKeyStore.markdownerAPIKey
    }

    func save() {
        apiKeyStore.googlePlacesAPIKey = googlePlacesAPIKey
        apiKeyStore.openRouterAPIKey = openRouterAPIKey
        apiKeyStore.markdownerAPIKey = markdownerAPIKey
    }
}
