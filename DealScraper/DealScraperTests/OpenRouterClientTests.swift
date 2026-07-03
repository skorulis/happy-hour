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

    @Test func sendsWebpageRequestWithWebFetchTool() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "choices": [
                    {
                      "message": {
                        "content": "{\\"deals\\":[{\\"title\\":\\"TACO TUESDAY\\",\\"details\\":[\\"$2 TACOS\\"],\\"conditions\\":[],\\"days\\":[\\"TUESDAY\\"],\\"times\\":[\\"all day\\"]}]}"
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

        let payload = try await client.extractDealsFromWebpage(
            url: "https://pub.example.com/specials",
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        let request = try #require(captured.request)
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect(tools.count == 1)
        #expect(tools[0]["type"] as? String == "openrouter:web_fetch")

        let parameters = try #require(tools[0]["parameters"] as? [String: Any])
        #expect(parameters["max_uses"] as? Int == 1)

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 2)
        #expect(messages[1]["content"] as? String == """
        Extract all deals from the visible text on this webpage.

        https://pub.example.com/specials
        """)

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "TACO TUESDAY")
    }

    @Test func sendsMarkdownRequestWithoutWebFetchTool() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "choices": [
                    {
                      "message": {
                        "content": "{\\"deals\\":[{\\"title\\":\\"WING WEDNESDAY\\",\\"details\\":[\\"$1 WINGS\\"],\\"conditions\\":[],\\"days\\":[\\"WEDNESDAY\\"],\\"times\\":[\\"all day\\"]}]}"
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

        let markdown = "# Happy Hour\n\n$5 beers every Friday 4-6pm"
        let payload = try await client.extractDealsFromMarkdown(
            markdown: markdown,
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        let request = try #require(captured.request)
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(json["tools"] == nil)

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 2)
        #expect(messages[1]["content"] as? String == """
        Extract all deals from the webpage markdown below.

        \(markdown)
        """)

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "WING WEDNESDAY")
    }

    @Test func sendsPDFTextRequestWithoutWebFetchTool() async throws {
        let captured = RequestCapture()

        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                captured.request = request

                let responseData = """
                {
                  "choices": [
                    {
                      "message": {
                        "content": "{\\"deals\\":[{\\"title\\":\\"HAPPY HOUR\\",\\"details\\":[\\"$5 BEERS\\"],\\"conditions\\":[],\\"days\\":[\\"MONDAY\\"],\\"times\\":[\\"4PM - 6PM\\"]}]}"
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

        let pdfText = "Monday happy hour $5 beers 4pm to 6pm"
        let payload = try await client.extractDealsFromText(
            text: pdfText,
            extractionTask: VenueDealInstructions.pdfExtractionTask,
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        let request = try #require(captured.request)
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(json["tools"] == nil)

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 2)
        #expect(messages[1]["content"] as? String == """
        \(VenueDealInstructions.pdfExtractionTask)

        \(pdfText)
        """)

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
    }

    @Test func parsesMarkdownWrappedBareArrayWebpageResponse() async throws {
        let client = OpenRouterClient(
            urlSession: FakeURLSession { request in
                let responseData = """
                {
                  "choices": [
                    {
                      "message": {
                        "content": "```json\\n[\\n    {\\n        \\"title\\": \\"Happy Hour\\",\\n        \\"details\\": \\"$10 house wines, beers and spirits\\",\\n        \\"conditions\\": \\"To avail of the 2-for-$30 spritzes, you must order 2 of the same spritz.\\",\\n        \\"days\\": \\"Monday - Friday\\",\\n        \\"times\\": \\"5-7pm\\"\\n    }\\n]\\n```"
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

        let payload = try await client.extractDealsFromWebpage(
            url: "https://pub.example.com/specials",
            apiKey: "test-key",
            model: "google/gemini-2.5-pro",
            instructions: "test instructions"
        )

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "Happy Hour")
        #expect(payload.deals.first?.details == ["$10 house wines, beers and spirits"])
        #expect(payload.deals.first?.days == ["Monday - Friday"])
        #expect(payload.deals.first?.times == ["5-7pm"])
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

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "google/gemini-2.5-pro")

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
        #expect(messages[0]["content"] as? String == prompt)

        #expect(text == "A friendly local pub with cold schooners and a sunny beer garden.")
    }
}

private final class RequestCapture {
    var request: URLRequest?
}
