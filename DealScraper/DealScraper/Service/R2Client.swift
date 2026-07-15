//Created by Alex Skorulis on 15/7/2026.

import ASKCore
import Foundation

enum R2ClientError: LocalizedError {
    case notConfigured
    case invalidPublicURL
    case uploadFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloudflare R2 is not configured. Add account ID and API keys in Settings."
        case .invalidPublicURL:
            return "R2 public base URL is invalid."
        case .uploadFailed(let statusCode):
            return "R2 upload failed (HTTP \(statusCode))."
        }
    }
}

@MainActor
protocol VenueHeroImageUploading {
    var isConfigured: Bool { get }
    func uploadHero(venueId: Int64, jpegData: Data) async throws -> URL
}

@MainActor
final class R2Client: HTTPService, VenueHeroImageUploading {

    /// Stable per-venue keys overwrite on replace; avoid `immutable` so updates can refresh.
    static let cacheControl = "public, max-age=86400"
    static let contentType = "image/jpeg"

    private let configStore: R2ConfigStore

    init(
        configStore: R2ConfigStore,
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = nil
    ) {
        self.configStore = configStore
        super.init(baseURL: nil, logger: logger, urlSession: urlSession)
    }

    var isConfigured: Bool {
        configStore.isConfigured
    }

    func objectKey(venueId: Int64) -> String {
        "venues/\(venueId).jpg"
    }

    func publicURL(for objectKey: String) throws -> URL {
        let base = configStore.publicBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: base) else {
            throw R2ClientError.invalidPublicURL
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let keyPath = objectKey.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [path, keyPath].filter { !$0.isEmpty }.joined(separator: "/")
        components.query = nil
        components.fragment = nil
        guard let url = components.url else {
            throw R2ClientError.invalidPublicURL
        }
        return url
    }

    func uploadHero(venueId: Int64, jpegData: Data) async throws -> URL {
        guard isConfigured else {
            throw R2ClientError.notConfigured
        }

        let key = objectKey(venueId: venueId)
        let putURL = try putObjectURL(objectKey: key)
        let signed = try AWSS3SigV4.signPUT(
            url: putURL,
            body: jpegData,
            contentType: Self.contentType,
            cacheControl: Self.cacheControl,
            accessKeyId: configStore.accessKeyId,
            secretAccessKey: configStore.secretAccessKey
        )

        let request = R2PutObjectRequest(
            endpoint: signed.url.absoluteString,
            body: signed.body,
            headers: signed.headers
        )
        _ = try await execute(request: request)
        return try publicURL(for: key)
    }

    private func putObjectURL(objectKey: String) throws -> URL {
        let accountId = configStore.accountId.trimmingCharacters(in: .whitespacesAndNewlines)
        let bucket = configStore.bucket.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "\(accountId).r2.cloudflarestorage.com"
        components.path = "/\(bucket)/\(objectKey)"
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
}

private struct R2PutObjectRequest: HTTPRequest {
    typealias ResponseType = Void

    let endpoint: String
    let method: String = "PUT"
    let body: Data?
    let headers: [String: String]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        // HTTPService already rejects >= 400; accept 200/201/204.
        guard (200...299).contains(http.statusCode) else {
            throw R2ClientError.uploadFailed(statusCode: http.statusCode)
        }
    }
}
