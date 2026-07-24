//Created by Alex Skorulis on 24/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct ExtractProductsAPIClientTests {

    @Test func postsTitleAndDetailsToBackend() async throws {
        let captured = RequestCapture()

        let client = ExtractProductsAPIClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "products": [
                    { "name": "cocktails", "price": null },
                    { "name": "beer", "price": null }
                  ]
                }
                """.data(using: .utf8)!

                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let payload = try await client.extractProducts(
            baseURL: "http://localhost:3000",
            title: "$14 Cocktails",
            details: "happy hour beers"
        )

        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:3000/api/extract-products")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["title"] as? String == "$14 Cocktails")
        #expect(json["details"] as? String == "happy hour beers")

        #expect(payload.products.count == 2)
        #expect(payload.products[0].name == "cocktails")
        #expect(payload.products[0].price == nil)
        #expect(payload.products[1].name == "beer")
    }

    @Test func surfacesBackendErrorMessage() async throws {
        let client = ExtractProductsAPIClient(
            urlSession: FakeURLSession { request in
                let responseData = """
                {"error":"Missing title"}
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
            _ = try await client.extractProducts(
                baseURL: "http://localhost:3000",
                title: nil,
                details: nil
            )
            Issue.record("Expected request to fail")
        } catch let error as ExtractProductsAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Expected apiError")
                return
            }
            #expect(statusCode == 400)
            #expect(message == "Missing title")
        }
    }
}

private final class RequestCapture {
    var request: URLRequest?
}
