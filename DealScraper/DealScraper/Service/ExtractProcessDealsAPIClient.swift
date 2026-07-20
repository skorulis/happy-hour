//Created by Alex Skorulis on 20/7/2026.

import ASKCore
import Foundation

@MainActor
final class ExtractProcessDealsAPIClient {

    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol? = nil) {
        if let urlSession {
            self.urlSession = urlSession
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 120
            configuration.timeoutIntervalForResource = 180
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    func extractProcessDeals(
        baseURL: String,
        venueName: String,
        model: String,
        openRouterAPIKey: String,
        material: VenueDealSourceMaterial
    ) async throws -> ProcessedDealPayload {
        let request = try ExtractProcessDealsAPI.extractProcessDealsRequest(
            baseURL: baseURL,
            venueName: venueName,
            model: model,
            openRouterAPIKey: openRouterAPIKey,
            material: material
        )

        guard let url = URL(string: request.endpoint) else {
            throw ExtractProcessDealsAPI.Error.invalidBackendURL(request.endpoint)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers

        let (data, response) = try await urlSession.data(for: urlRequest)
        return try request.decode(data: data, response: response)
    }
}
