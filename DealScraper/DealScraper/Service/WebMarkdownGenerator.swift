//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation

enum WebMarkdownGeneratorError: LocalizedError {
    case invalidResponse
    case rateLimitExceeded
    case emptyContent
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The markdown service returned an invalid response."
        case .rateLimitExceeded:
            return "The markdown service rate limit was exceeded."
        case .emptyContent:
            return "The markdown service returned no content."
        case let .apiError(statusCode, message):
            return "The markdown service returned an error (\(statusCode)): \(message)"
        }
    }
}

@MainActor
final class WebMarkdownGenerator: HTTPService {

    private let session: URLSessionProtocol
    private let requestHandler: ((MarkdownRequest) async throws -> String)?

    init(
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = nil
    ) {
        self.session = urlSession
        self.requestHandler = nil
        super.init(baseURL: "https://md.dhr.wtf", logger: logger, urlSession: urlSession)
    }

    init(requestHandler: @escaping (MarkdownRequest) async throws -> String) {
        self.session = URLSession.shared
        self.requestHandler = requestHandler
        super.init(baseURL: "https://md.dhr.wtf", logger: nil)
    }

    func markdown(for url: URL, apiKey: String = "") async throws -> String {
        let request = MarkdownRequest(sourceURL: url, apiKey: apiKey)
        if let requestHandler {
            return try await requestHandler(request)
        }
        return try await execute(request: request)
    }
}

struct MarkdownRequest: HTTPRequest {
    typealias ResponseType = String

    let sourceURL: URL
    let apiKey: String

    var endpoint: String { "https://md.dhr.wtf/" }
    let method: String = "GET"
    let body: Data? = nil
    var params: [String: String] { ["url": sourceURL.absoluteString] }

    var headers: [String: String] {
        var headers = ["Accept": "text/plain"]
        if !apiKey.isEmpty {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        return headers
    }

    func decode(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebMarkdownGeneratorError.invalidResponse
        }

        let message = String(data: data, encoding: .utf8) ?? ""
        
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WebMarkdownGeneratorError.emptyContent
        }
        return trimmed
    }
}
