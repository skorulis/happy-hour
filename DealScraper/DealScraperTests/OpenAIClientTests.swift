//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct OpenAIClientTests {

    @Test func sendsVisionRequestWithAuthAndJsonSchema() async throws {
        let captured = RequestCapture()

        let client = OpenAIClient { request in
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

        let payload = try await client.extractDeals(
            imageBase64: "abc123",
            mimeType: "image/jpeg",
            apiKey: "test-key",
            model: "gpt-4o",
            instructions: "test instructions"
        )

        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "gpt-4o")

        let responseFormat = try #require(json["response_format"] as? [String: Any])
        #expect(responseFormat["type"] as? String == "json_schema")

        let jsonSchema = try #require(responseFormat["json_schema"] as? [String: Any])
        #expect(jsonSchema["name"] as? String == "deal_extraction")
        #expect(jsonSchema["strict"] as? Bool == true)

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 2)

        let userContent = try #require(messages[1]["content"] as? [[String: Any]])
        #expect(userContent.count == 2)
        #expect(userContent[0]["type"] as? String == "text")
        #expect(userContent[1]["type"] as? String == "image_url")

        let imageURL = try #require(userContent[1]["image_url"] as? [String: Any])
        let url = try #require(imageURL["url"] as? String)
        #expect(url.hasPrefix("data:image/jpeg;base64,"))

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
        #expect(payload.deals.first?.details == ["$8 WINES"])
    }

    @Test func throwsAPIErrorOnNonSuccessStatus() async throws {
        let client = OpenAIClient { request in
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

        do {
            _ = try await client.extractDeals(
                imageBase64: "abc",
                mimeType: "image/jpeg",
                apiKey: "bad-key",
                model: "gpt-4o",
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

private final class RequestCapture: @unchecked Sendable {
    var request: URLRequest?
}
