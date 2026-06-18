//Created by Alex Skorulis on 19/6/2026.

import ASKCore
import Foundation

enum CrawlPDFFetcherError: LocalizedError {
    case invalidResponse
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The PDF download returned an invalid response."
        case .emptyData:
            return "The PDF download returned no data."
        }
    }
}

@MainActor
final class CrawlPDFFetcher: HTTPService {

    private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private let cache: CrawlPDFCache

    init(
        cache: CrawlPDFCache,
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

        let request = PDFDownloadRequest(endpoint: remoteURL.absoluteString)
        let result: PDFDownloadResponse
        do {
            result = try await execute(request: request)
        } catch {
            throw CrawlPDFFetcherError.invalidResponse
        }

        guard !result.data.isEmpty else {
            throw CrawlPDFFetcherError.emptyData
        }

        let fileExtension = Self.fileExtension(for: remoteURL, response: result.response)
        return try cache.store(data: result.data, hash: hash, fileExtension: fileExtension)
    }

    private static func fileExtension(for url: URL, response: HTTPURLResponse) -> String {
        let pathExtension = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return pathExtension
        }

        if let mimeType = response.mimeType?.lowercased(), mimeType == "application/pdf" {
            return "pdf"
        }

        return "pdf"
    }
}

private struct PDFDownloadResponse {
    let data: Data
    let response: HTTPURLResponse
}

private struct PDFDownloadRequest: HTTPRequest {
    typealias ResponseType = PDFDownloadResponse

    let endpoint: String
    let method: String = "GET"
    let body: Data? = nil
    let headers: [String: String] = [:]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> PDFDownloadResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CrawlPDFFetcherError.invalidResponse
        }
        return PDFDownloadResponse(data: data, response: httpResponse)
    }
}
