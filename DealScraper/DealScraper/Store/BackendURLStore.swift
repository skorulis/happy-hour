//Created by Alex Skorulis on 20/7/2026.

import ASKCore
import Foundation

final class BackendURLStore {

    static let defaultBackendURL = "http://localhost:3000"
    static let productionBackendURL = "https://duskroute.com"

    private static let key = "dealScraper.backendURL"

    private let keyValueStore: PKeyValueStore

    init(keyValueStore: PKeyValueStore) {
        self.keyValueStore = keyValueStore
    }

    var backendURL: String {
        get {
            let stored = keyValueStore.string(forKey: Self.key) ?? ""
            let value = stored.isEmpty ? Self.defaultBackendURL : stored
            return value.hasSuffix("/") ? String(value.dropLast()) : value
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
            if normalized.isEmpty {
                keyValueStore.removeObject(forKey: Self.key)
            } else {
                keyValueStore.set(normalized, forKey: Self.key)
            }
        }
    }
}
