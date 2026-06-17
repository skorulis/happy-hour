//Created by Alex Skorulis on 17/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct CursorClientTests {

    @Test func createsAgentAndPollsRunUntilFinished() async throws {
        let captured = RequestCapture()
        let agentID = "bc-00000000-0000-0000-0000-000000000001"
        let runID = "run-00000000-0000-0000-0000-000000000001"

        let client = CursorClient(
            fetch: { request in
                captured.requests.append(request)

                if request.httpMethod == "POST", request.url?.path.hasSuffix("/v1/agents") == true,
                   !request.url!.path.contains("/archive")
                {
                    let responseData = """
                    {
                      "agent": { "id": "\(agentID)" },
                      "run": { "id": "\(runID)" }
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "GET",
                   request.url?.path == "/v1/agents/\(agentID)/runs/\(runID)"
                {
                    let responseData = """
                    {
                      "id": "\(runID)",
                      "status": "FINISHED",
                      "result": "{\\"deals\\":[{\\"title\\":\\"HAPPY HOUR\\",\\"details\\":[\\"$8 WINES\\"],\\"days\\":[\\"FRIDAY\\"],\\"times\\":[\\"4PM - 6PM\\"]}]}"
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "POST",
                   request.url?.path == "/v1/agents/\(agentID)/archive"
                {
                    return (Data(), HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                Issue.record("Unexpected request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
                return (Data(), HTTPURLResponse(
                    url: request.url!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            },
            sleep: { _ in }
        )

        let payload = try await client.extractDeals(
            imageBase64: "abc123",
            mimeType: "image/jpeg",
            apiKey: "test-key",
            model: "composer-2.5",
            instructions: "test instructions"
        )

        let createRequest = try #require(captured.requests.first)
        #expect(createRequest.httpMethod == "POST")
        #expect(createRequest.url?.absoluteString == "https://api.cursor.com/v1/agents")
        #expect(createRequest.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")

        let body = try #require(createRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        let prompt = try #require(json["prompt"] as? [String: Any])
        let promptText = try #require(prompt["text"] as? String)
        #expect(promptText.contains("test instructions"))
        #expect(promptText.contains("Return ONLY valid JSON"))

        let images = try #require(prompt["images"] as? [[String: Any]])
        #expect(images.count == 1)
        #expect(images[0]["data"] as? String == "abc123")
        #expect(images[0]["mimeType"] as? String == "image/jpeg")

        let model = try #require(json["model"] as? [String: Any])
        #expect(model["id"] as? String == "composer-2.5")

        #expect(payload.deals.count == 1)
        #expect(payload.deals.first?.title == "HAPPY HOUR")
        #expect(payload.deals.first?.details == ["$8 WINES"])
    }

    @Test func extractVenueDealsSendsMultipleImages() async throws {
        let captured = RequestCapture()
        let agentID = "bc-00000000-0000-0000-0000-000000000003"
        let runID = "run-00000000-0000-0000-0000-000000000003"

        let client = CursorClient(
            fetch: { request in
                captured.requests.append(request)

                if request.httpMethod == "POST", request.url?.path.hasSuffix("/v1/agents") == true,
                   !request.url!.path.contains("/archive")
                {
                    let responseData = """
                    {
                      "agent": { "id": "\(agentID)" },
                      "run": { "id": "\(runID)" }
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "GET",
                   request.url?.path == "/v1/agents/\(agentID)/runs/\(runID)"
                {
                    let responseData = """
                    {
                      "id": "\(runID)",
                      "status": "FINISHED",
                      "result": "{\\"deals\\":[{\\"title\\":\\"HAPPY HOUR\\",\\"details\\":[\\"$8 WINES\\"],\\"conditions\\":[],\\"days\\":[\\"FRIDAY\\"],\\"times\\":[\\"4PM - 6PM\\"],\\"sourceIndices\\":[1,2]}]}"
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                return (Data(), HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            },
            sleep: { _ in }
        )

        let payload = try await client.extractVenueDeals(
            images: [
                (base64: "image-one", mimeType: "image/png"),
                (base64: "image-two", mimeType: "image/png"),
            ],
            promptText: CursorClient.jsonPrompt(from: "venue extraction"),
            model: "composer-2.5",
            apiKey: "test-key"
        )

        let createRequest = try #require(captured.requests.first)
        let body = try #require(createRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let prompt = try #require(json["prompt"] as? [String: Any])
        let images = try #require(prompt["images"] as? [[String: Any]])

        #expect(images.count == 2)
        #expect(images[0]["data"] as? String == "image-one")
        #expect(images[1]["data"] as? String == "image-two")
        #expect(payload.deals.first?.sourceIndices == [1, 2])
    }

    @Test func throwsAPIErrorOnNonSuccessStatus() async throws {
        let client = CursorClient { request in
            let responseData = """
            {"message":"Invalid API key"}
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
                model: "composer-2.5",
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

    @Test func throwsAPIErrorWhenRunFails() async throws {
        let agentID = "bc-00000000-0000-0000-0000-000000000002"
        let runID = "run-00000000-0000-0000-0000-000000000002"

        let client = CursorClient(
            fetch: { request in
                if request.httpMethod == "POST", request.url?.path.hasSuffix("/v1/agents") == true,
                   !request.url!.path.contains("/archive")
                {
                    let responseData = """
                    {
                      "agent": { "id": "\(agentID)" },
                      "run": { "id": "\(runID)" }
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "GET",
                   request.url?.path == "/v1/agents/\(agentID)/runs/\(runID)"
                {
                    let responseData = """
                    {
                      "id": "\(runID)",
                      "status": "ERROR"
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                return (Data(), HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            },
            sleep: { _ in }
        )

        do {
            _ = try await client.extractDeals(
                imageBase64: "abc",
                mimeType: "image/jpeg",
                apiKey: "test-key",
                model: "composer-2.5",
                instructions: "test"
            )
            Issue.record("Expected API error")
        } catch let error as VisionDealAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Unexpected error type: \(error)")
                return
            }
            #expect(statusCode == 0)
            #expect(message == "Agent run ended with status ERROR")
        }
    }
}

private final class RequestCapture: @unchecked Sendable {
    var requests: [URLRequest] = []
}
