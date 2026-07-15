//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SettingsViewModel: CoordinatorViewModel {

    weak var coordinator: ASKCoordinator.Coordinator?

    var googlePlacesAPIKey: String = ""
    var openRouterAPIKey: String = ""
    var markdownerAPIKey: String = ""

    var r2AccountId: String = ""
    var r2Bucket: String = ""
    var r2PublicBaseURL: String = ""
    var r2AccessKeyId: String = ""
    var r2SecretAccessKey: String = ""

    private let apiKeyStore: APIKeyStore
    private let r2ConfigStore: R2ConfigStore

    @Resolvable<Resolver>
    init(apiKeyStore: APIKeyStore, r2ConfigStore: R2ConfigStore) {
        self.apiKeyStore = apiKeyStore
        self.r2ConfigStore = r2ConfigStore
        load()
    }

    func load() {
        googlePlacesAPIKey = apiKeyStore.googlePlacesAPIKey
        openRouterAPIKey = apiKeyStore.openRouterAPIKey
        markdownerAPIKey = apiKeyStore.markdownerAPIKey

        r2AccountId = r2ConfigStore.accountId
        r2Bucket = r2ConfigStore.bucket
        r2PublicBaseURL = r2ConfigStore.publicBaseURL
        r2AccessKeyId = r2ConfigStore.accessKeyId
        r2SecretAccessKey = r2ConfigStore.secretAccessKey
    }

    func save() {
        apiKeyStore.googlePlacesAPIKey = googlePlacesAPIKey
        apiKeyStore.openRouterAPIKey = openRouterAPIKey
        apiKeyStore.markdownerAPIKey = markdownerAPIKey

        r2ConfigStore.accountId = r2AccountId
        r2ConfigStore.bucket = r2Bucket
        r2ConfigStore.publicBaseURL = r2PublicBaseURL
        r2ConfigStore.accessKeyId = r2AccessKeyId
        r2ConfigStore.secretAccessKey = r2SecretAccessKey
    }

    func showStats() {
        coordinator?.push(MainPath.stats)
    }
}
