//Created by Alex Skorulis on 27/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct FormatDealTextAPIClientTests {

    @Test func postsTitleToBackend() async throws {
        let captured = RequestCapture()

        let client = FormatDealTextAPIClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {"title":"Happy Hour"}
                """.data(using: .utf8)!

                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let formatted = try await client.formatTitle(
            baseURL: "http://localhost:3000",
            title: "HAPPY HOUR"
        )

        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:3000/api/format-deal-text")
        #expect(request.httpMethod == "POST")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["title"] as? String == "HAPPY HOUR")
        #expect(json["details"] == nil)

        #expect(formatted == "Happy Hour")
    }

    @Test func postsDetailsToBackend() async throws {
        let captured = RequestCapture()

        let client = FormatDealTextAPIClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {"details":"$8 Schooners"}
                """.data(using: .utf8)!

                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let formatted = try await client.formatDetails(
            baseURL: "http://localhost:3000",
            details: "$8 SCHOONERS"
        )

        let request = try #require(captured.request)
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["details"] as? String == "$8 SCHOONERS")
        #expect(json["title"] == nil)

        #expect(formatted == "$8 Schooners")
    }

    @Test func surfacesBackendErrorMessage() async throws {
        let client = FormatDealTextAPIClient(
            urlSession: FakeURLSession { request in
                let responseData = """
                {"error":"Missing title or details"}
                """.data(using: .utf8)!
                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        do {
            _ = try await client.formatTitle(baseURL: "http://localhost:3000", title: nil)
            Issue.record("Expected request to fail")
        } catch let error as FormatDealTextAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Expected apiError")
                return
            }
            #expect(statusCode == 400)
            #expect(message == "Missing title or details")
        }
    }
}

private final class RequestCapture {
    var request: URLRequest?
}
