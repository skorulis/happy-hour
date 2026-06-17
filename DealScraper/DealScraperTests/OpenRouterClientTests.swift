//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct OpenRouterClientTests {

    @Test func sendsVisionRequestWithOpenRouterHeaders() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
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

                return (responseData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        )

        let payload = try await client.extractDeals(
            imageBase64: "abc123",
            mimeType: "image/jpeg",
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        let request = try #require(captured.request)
        #expect(request.url?.path.hasSuffix("/v1/chat/completions") == true)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.value(forHTTPHeaderField: "HTTP-Referer") == "https://github.com/skorulis/happy-hour")
        #expect(request.value(forHTTPHeaderField: "X-Title") == "DealScraper")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "google/gemini-2.5-pro")

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
    }

    @Test func throwsOnNonSuccessStatus() async throws {
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
            Issue.record("Expected request to fail")
        } catch let error as URLError {
            #expect(error.code == .badServerResponse)
        }
    }
}

private final class RequestCapture {
    var request: URLRequest?
}
