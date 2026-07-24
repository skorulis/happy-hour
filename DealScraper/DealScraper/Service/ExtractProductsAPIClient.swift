//Created by Alex Skorulis on 24/7/2026.

import ASKCore
import Foundation

@MainActor
final class ExtractProductsAPIClient {

    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol? = nil) {
        if let urlSession {
            self.urlSession = urlSession
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    func extractProducts(
        baseURL: String,
        title: String?,
        details: String?
    ) async throws -> ExtractProductsPayload {
        let request = try ExtractProductsAPI.extractProductsRequest(
            baseURL: baseURL,
            title: title,
            details: details
        )

        guard let url = URL(string: request.endpoint) else {
            throw ExtractProductsAPI.Error.invalidBackendURL(request.endpoint)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers

        let (data, response) = try await urlSession.data(for: urlRequest)
        return try request.decode(data: data, response: response)
    }
}
