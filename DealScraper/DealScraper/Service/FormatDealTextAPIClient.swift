//Created by Alex Skorulis on 27/7/2026.

import ASKCore
import Foundation

@MainActor
final class FormatDealTextAPIClient {

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

    func formatTitle(baseURL: String, title: String?) async throws -> String? {
        let payload = try await formatDealText(
            baseURL: baseURL,
            title: title,
            details: nil,
            includeTitle: true,
            includeDetails: false
        )
        return payload.title
    }

    func formatDetails(baseURL: String, details: String?) async throws -> String? {
        let payload = try await formatDealText(
            baseURL: baseURL,
            title: nil,
            details: details,
            includeTitle: false,
            includeDetails: true
        )
        return payload.details
    }

    private func formatDealText(
        baseURL: String,
        title: String?,
        details: String?,
        includeTitle: Bool,
        includeDetails: Bool
    ) async throws -> FormatDealTextPayload {
        let request = try FormatDealTextAPI.formatDealTextRequest(
            baseURL: baseURL,
            title: title,
            details: details,
            includeTitle: includeTitle,
            includeDetails: includeDetails
        )

        guard let url = URL(string: request.endpoint) else {
            throw FormatDealTextAPI.Error.invalidBackendURL(request.endpoint)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers

        let (data, response) = try await urlSession.data(for: urlRequest)
        return try request.decode(data: data, response: response)
    }
}
