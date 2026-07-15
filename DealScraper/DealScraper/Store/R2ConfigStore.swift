//Created by Alex Skorulis on 15/7/2026.

import ASKCore
import Foundation

final class R2ConfigStore {

    static let defaultBucket = "duskroute-heroes"
    static let defaultPublicBaseURL = "https://images.duskroute.com"

    private enum SecureKey {
        static let accessKeyId = "r2AccessKeyId"
        static let secretAccessKey = "r2SecretAccessKey"
    }

    private enum PrefKey {
        static let accountId = "dealScraper.r2AccountId"
        static let bucket = "dealScraper.r2Bucket"
        static let publicBaseURL = "dealScraper.r2PublicBaseURL"
    }

    private let secureStore: SecureKeyValueStore
    private let keyValueStore: PKeyValueStore

    init(secureStore: SecureKeyValueStore, keyValueStore: PKeyValueStore) {
        self.secureStore = secureStore
        self.keyValueStore = keyValueStore
    }

    var accountId: String {
        get { keyValueStore.string(forKey: PrefKey.accountId) ?? "" }
        set { setPref(newValue, forKey: PrefKey.accountId) }
    }

    var bucket: String {
        get {
            let stored = keyValueStore.string(forKey: PrefKey.bucket) ?? ""
            return stored.isEmpty ? Self.defaultBucket : stored
        }
        set { setPref(newValue, forKey: PrefKey.bucket) }
    }

    var publicBaseURL: String {
        get {
            let stored = keyValueStore.string(forKey: PrefKey.publicBaseURL) ?? ""
            let value = stored.isEmpty ? Self.defaultPublicBaseURL : stored
            return value.hasSuffix("/") ? String(value.dropLast()) : value
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
            setPref(normalized, forKey: PrefKey.publicBaseURL)
        }
    }

    var accessKeyId: String {
        get { secureStore.string(forKey: SecureKey.accessKeyId) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: SecureKey.accessKeyId) }
    }

    var secretAccessKey: String {
        get { secureStore.string(forKey: SecureKey.secretAccessKey) ?? "" }
        set { secureStore.set(newValue.isEmpty ? nil : newValue, forKey: SecureKey.secretAccessKey) }
    }

    var isConfigured: Bool {
        !accountId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bucket.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !publicBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !accessKeyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !secretAccessKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func setPref(_ value: String, forKey key: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            keyValueStore.removeObject(forKey: key)
        } else {
            keyValueStore.set(trimmed, forKey: key)
        }
    }
}
