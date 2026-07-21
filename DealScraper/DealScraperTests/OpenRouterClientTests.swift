//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct OpenRouterClientTests {

    @Test func sendsTextCompletionRequest() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "choices": [
                    {
                      "message": {
                        "content": "A friendly local pub with cold schooners and a sunny beer garden."
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

        let prompt = "Give me a light hearted short description of The Royal Pub in Newtown"
        let text = try await client.generateText(
            prompt: prompt,
            apiKey: "test-key",
            model: "google/gemini-2.5-pro"
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

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
        #expect(messages[0]["content"] as? String == prompt)

        #expect(text == "A friendly local pub with cold schooners and a sunny beer garden.")
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
            _ = try await client.generateText(
                prompt: "test",
                apiKey: "bad-key",
                model: "openai/gpt-4o"
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
