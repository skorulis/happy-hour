//Created by Alex Skorulis on 20/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct ExtractDealsAPIClientTests {

    @Test func postsPreparedImageSourceToBackend() async throws {
        let captured = RequestCapture()

        let client = ExtractDealsAPIClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "deals": [
                    {
                      "title": "HAPPY HOUR",
                      "details": ["$8 WINES"],
                      "conditions": [],
                      "days": ["FRIDAY"],
                      "times": ["4PM - 6PM"],
                      "promotionDates": null
                    }
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

        let material = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 42,
            url: URL(string: "https://example.com/poster.png")!,
            sourceURL: URL(string: "https://example.com/")!,
            type: .image,
            pngData: Data("png".utf8),
            markdown: nil
        )

        let payload = try await client.extractDeals(
            baseURL: "http://localhost:3000",
            venueName: "The Local",
            model: "google/gemini-2.5-pro",
            material: material
        )

        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:3000/api/extract-deals")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["venueName"] as? String == "The Local")
        #expect(json["model"] as? String == "google/gemini-2.5-pro")

        let source = try #require(json["source"] as? [String: Any])
        #expect(source["type"] as? String == "image")
        #expect(source["imageBase64"] as? String == Data("png".utf8).base64EncodedString())
        #expect(source["mimeType"] as? String == "image/png")

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
    }

    @Test func surfacesBackendErrorMessage() async throws {
        let client = ExtractDealsAPIClient(
            urlSession: FakeURLSession { request in
                let responseData = """
                {"error":"Image exceeds maximum size"}
                """.data(using: .utf8)!
                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 413,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let material = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 1,
            url: URL(string: "https://example.com/poster.png")!,
            sourceURL: URL(string: "https://example.com/")!,
            type: .image,
            pngData: Data("png".utf8),
            markdown: nil
        )

        do {
            _ = try await client.extractDeals(
                baseURL: "http://localhost:3000",
                venueName: "The Local",
                model: "google/gemini-2.5-pro",
                material: material
            )
            Issue.record("Expected request to fail")
        } catch let error as ExtractDealsAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Expected apiError")
                return
            }
            #expect(statusCode == 413)
            #expect(message == "Image exceeds maximum size")
        }
    }
}

private final class RequestCapture {
    var request: URLRequest?
}
