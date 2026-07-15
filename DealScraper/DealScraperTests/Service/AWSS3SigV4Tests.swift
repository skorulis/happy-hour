//Created by Alex Skorulis on 15/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

struct AWSS3SigV4Tests {

    @Test func signsPutWithRequiredHeaders() throws {
        let url = URL(string: "https://acct.r2.cloudflarestorage.com/duskroute-heroes/venues/1.jpg")!
        let body = Data("hello".utf8)
        let date = ISO8601DateFormatter().date(from: "2026-07-15T02:00:00Z")!

        let signed = try AWSS3SigV4.signPUT(
            url: url,
            body: body,
            contentType: "image/jpeg",
            cacheControl: "public, max-age=31536000, immutable",
            accessKeyId: "AKIAEXAMPLE",
            secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            date: date
        )

        #expect(signed.method == "PUT")
        #expect(signed.headers["host"] == "acct.r2.cloudflarestorage.com")
        #expect(signed.headers["content-type"] == "image/jpeg")
        #expect(signed.headers["x-amz-date"] == "20260715T020000Z")
        #expect(signed.headers["authorization"]?.hasPrefix("AWS4-HMAC-SHA256 Credential=AKIAEXAMPLE/") == true)
        #expect(signed.headers["authorization"]?.contains("SignedHeaders=") == true)
        #expect(signed.headers["authorization"]?.contains("Signature=") == true)
        #expect(signed.body == body)
    }
}

@MainActor
struct R2ConfigStoreTests {

    @Test func defaultsAndConfiguredFlag() {
        let memory = InMemoryKeyValueStore()
        let store = R2ConfigStore(secureStore: memory, keyValueStore: memory)

        #expect(store.bucket == R2ConfigStore.defaultBucket)
        #expect(store.publicBaseURL == R2ConfigStore.defaultPublicBaseURL)
        #expect(!store.isConfigured)

        store.accountId = "acct"
        store.accessKeyId = "key"
        store.secretAccessKey = "secret"
        #expect(store.isConfigured)
    }

    @Test func stripsTrailingSlashFromPublicBaseURL() {
        let memory = InMemoryKeyValueStore()
        let store = R2ConfigStore(secureStore: memory, keyValueStore: memory)
        store.publicBaseURL = "https://images.duskroute.com/"
        #expect(store.publicBaseURL == "https://images.duskroute.com")
    }
}
