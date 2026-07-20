//Created by Alex Skorulis on 20/7/2026.

import ASKCore
import Foundation

@MainActor
final class ExtractDealsAPIClient {

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

    func extractDeals(
        baseURL: String,
        venueName: String,
        model: String,
        material: VenueDealSourceMaterial
    ) async throws -> DealExtractionPayload {
        let request = try ExtractDealsAPI.extractDealsRequest(
            baseURL: baseURL,
            venueName: venueName,
            model: model,
            material: material
        )

        guard let url = URL(string: request.endpoint) else {
            throw ExtractDealsAPI.Error.invalidBackendURL(request.endpoint)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers

        let (data, response) = try await urlSession.data(for: urlRequest)
        return try request.decode(data: data, response: response)
    }
}
