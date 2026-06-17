//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct OpenRouterClientTests {

    @Test func sendsVisionRequestWithOpenRouterHeaders() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient { request in
            captured.request = request

            let responseData = """
            {
              "choices": [
                {
                  "message": {
                    "content": "{\\"deals\\":[{\\"title\\":\\"HAPPY HOUR\\",\\"details\\":[\\"$8 WINES\\"],\\"days\\":[\\"FRIDAY\\"],\\"times\\":[\\"4PM - 6PM\\"]}]}"
                  }
                }
              ]
            }
            """.data(using: .utf8)!

            return try VisionDealAPI.parseDealExtractionPayload(from: responseData)
        }

        let payload = try await client.extractDeals(
            imageBase64: "abc123",
            mimeType: "image/jpeg",
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        let request = try #require(captured.request as? ExtractDealsRequest)
        #expect(request.endpoint == "v1/chat/completions")
        #expect(request.method == "POST")
        #expect(request.headers["Authorization"] == "Bearer test-key")
        #expect(request.headers["HTTP-Referer"] == "https://github.com/skorulis/happy-hour")
        #expect(request.headers["X-Title"] == "DealScraper")

        let body = try #require(request.body)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "google/gemini-2.5-pro")

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
    }

    @Test func throwsAPIErrorOnNonSuccessStatus() async throws {
        let client = OpenRouterClient { _ in
            throw VisionDealAPI.Error.apiError(statusCode: 401, message: "Invalid API key")
        }

        do {
            _ = try await client.extractDeals(
                imageBase64: "abc",
                mimeType: "image/jpeg",
                apiKey: "bad-key",
                model: "openai/gpt-4o",
                instructions: "test"
            )
            Issue.record("Expected API error")
        } catch let error as VisionDealAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Unexpected error type: \(error)")
                return
            }
            #expect(statusCode == 401)
            #expect(message == "Invalid API key")
        }
    }

    @Test func throwsAPIErrorFromHTTPResponse() async throws {
        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                let responseData = """
                {"error":{"message":"Invalid API key"}}
                """.data(using: .utf8)!
                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        do {
            _ = try await client.extractDeals(
                imageBase64: "abc",
                mimeType: "image/jpeg",
                apiKey: "bad-key",
                model: "openai/gpt-4o",
                instructions: "test"
            )
            Issue.record("Expected API error")
        } catch let error as VisionDealAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Unexpected error type: \(error)")
                return
            }
            #expect(statusCode == 401)
            #expect(message == "Invalid API key")
        }
    }
}

private final class RequestCapture {
    var request: (any HTTPRequest)?
}
