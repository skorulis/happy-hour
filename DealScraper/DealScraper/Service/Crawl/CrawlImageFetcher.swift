//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation

enum CrawlImageFetcherError: LocalizedError {
    case invalidResponse
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The image download returned an invalid response."
        case .emptyData:
            return "The image download returned no data."
        }
    }
}

@MainActor
final class CrawlImageFetcher: HTTPService {

    private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private let cache: CrawlImageCache

    init(
        cache: CrawlImageCache,
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = nil
    ) {
        self.cache = cache
        super.init(baseURL: nil, logger: logger, urlSession: urlSession)
    }

    override func modify(request: inout URLRequest) throws {
        request.setValue(Self.safariUserAgent, forHTTPHeaderField: "User-Agent")
    }

    func localFileURL(for remoteURL: URL, hash: String) async throws -> URL {
        if let cached = cache.findCachedFileURL(for: hash) {
            return cached
        }

        let request = ImageDownloadRequest(endpoint: remoteURL.absoluteString)
        let result: ImageDownloadResponse
        do {
            result = try await execute(request: request)
        } catch {
            throw CrawlImageFetcherError.invalidResponse
        }

        guard !result.data.isEmpty else {
            throw CrawlImageFetcherError.emptyData
        }

        let fileExtension = Self.fileExtension(for: remoteURL, response: result.response)
        return try cache.store(data: result.data, hash: hash, fileExtension: fileExtension)
    }

    private static func fileExtension(for url: URL, response: HTTPURLResponse) -> String {
        let pathExtension = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return pathExtension
        }

        if let mimeType = response.mimeType?.lowercased() {
            switch mimeType {
            case "image/jpeg":
                return "jpg"
            case "image/png":
                return "png"
            case "image/gif":
                return "gif"
            case "image/webp":
                return "webp"
            case "image/avif":
                return "avif"
            default:
                break
            }
        }

        return "img"
    }
}

private struct ImageDownloadResponse {
    let data: Data
    let response: HTTPURLResponse
}

private struct ImageDownloadRequest: HTTPRequest {
    typealias ResponseType = ImageDownloadResponse

    let endpoint: String
    let method: String = "GET"
    let body: Data? = nil
    let headers: [String: String] = [:]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> ImageDownloadResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CrawlImageFetcherError.invalidResponse
        }
        return ImageDownloadResponse(data: data, response: httpResponse)
    }
}
