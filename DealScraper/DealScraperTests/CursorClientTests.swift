//Created by Alex Skorulis on 17/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct CursorClientTests {

    @Test func createsAgentAndPollsRunUntilFinished() async throws {
        let captured = RequestCapture()
        let agentID = "bc-00000000-0000-0000-0000-000000000001"
        let runID = "run-00000000-0000-0000-0000-000000000001"

        let client = CursorClient(
            urlSession: FakeURLSession { request in
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
            imageURL: URL(string: "https://example.com/poster.jpg")!,
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
        #expect(images[0]["url"] as? String == "https://example.com/poster.jpg")

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
            urlSession: FakeURLSession { request in
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
            imageURLs: [
                "https://example.com/image-one.png",
                "https://example.com/image-two.png",
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
        #expect(images[0]["url"] as? String == "https://example.com/image-one.png")
        #expect(images[1]["url"] as? String == "https://example.com/image-two.png")
        #expect(payload.deals.first?.sourceIndices == [1, 2])
    }

    @Test func reusesCreatedAgentForMultipleRunsAndArchivesOnce() async throws {
        let captured = RequestCapture()
        let agentID = "bc-00000000-0000-0000-0000-000000000010"
        let initialRunID = "run-00000000-0000-0000-0000-000000000010"
        let runTwoID = "run-00000000-0000-0000-0000-000000000012"

        let client = CursorClient(
            urlSession: FakeURLSession { request in
                captured.requests.append(request)

                if request.httpMethod == "POST", request.url?.path == "/v1/agents" {
                    let responseData = """
                    {
                      "agent": { "id": "\(agentID)" },
                      "run": { "id": "\(initialRunID)" }
                    }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "POST", request.url?.path == "/v1/agents/\(agentID)/runs" {
                    let responseData = """
                    { "id": "\(runTwoID)" }
                    """.data(using: .utf8)!
                    return (responseData, HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!)
                }

                if request.httpMethod == "GET",
                   request.url?.path == "/v1/agents/\(agentID)/runs/\(initialRunID)"
                {
                    let responseData = """
                    {
                      "id": "\(initialRunID)",
                      "status": "FINISHED",
                      "result": "{\\"deals\\":[{\\"title\\":\\"IMAGE DEAL\\",\\"details\\":[\\"$10\\"],\\"conditions\\":[],\\"days\\":[\\"MON\\"],\\"times\\":[\\"5PM - 7PM\\"],\\"sourceIndices\\":[1]}]}"
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
                   request.url?.path == "/v1/agents/\(agentID)/runs/\(runTwoID)"
                {
                    let responseData = """
                    {
                      "id": "\(runTwoID)",
                      "status": "FINISHED",
                      "result": "{\\"deals\\":[{\\"title\\":\\"WEB DEAL\\",\\"details\\":[\\"$12\\"],\\"conditions\\":[],\\"days\\":[\\"TUE\\"],\\"times\\":[\\"all day\\"],\\"sourceIndices\\":[2]}]}"
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

        let (agentIDResult, firstRunID) = try await client.createAgentRun(
            promptText: CursorClient.jsonPrompt(from: "source one"),
            imageURLs: ["https://example.com/source-image.png"],
            model: "composer-2.5",
            apiKey: "test-key"
        )
        #expect(agentIDResult == agentID)

        let firstPayload = try await client.pollRunForPayload(
            agentID: agentID,
            runID: firstRunID,
            apiKey: "test-key"
        )
        let secondPayload = try await client.extractVenueDeals(
            agentID: agentID,
            imageURLs: [],
            promptText: CursorClient.jsonPrompt(from: "source two"),
            model: "composer-2.5",
            apiKey: "test-key"
        )
        await client.archiveAgent(id: agentID, apiKey: "test-key")

        #expect(firstPayload.deals.first?.title == "IMAGE DEAL")
        #expect(secondPayload.deals.first?.title == "WEB DEAL")

        let createAgentRequests = captured.requests.filter { $0.httpMethod == "POST" && $0.url?.path == "/v1/agents" }
        let runCreationRequests = captured.requests.filter { $0.httpMethod == "POST" && $0.url?.path == "/v1/agents/\(agentID)/runs" }
        let archiveRequests = captured.requests.filter { $0.httpMethod == "POST" && $0.url?.path == "/v1/agents/\(agentID)/archive" }

        #expect(createAgentRequests.count == 1)
        #expect(runCreationRequests.count == 1)
        #expect(archiveRequests.count == 1)

        let createAgentBody = try #require(createAgentRequests.first?.httpBody)
        let createAgentJSON = try #require(JSONSerialization.jsonObject(with: createAgentBody) as? [String: Any])
        let createAgentPrompt = try #require(createAgentJSON["prompt"] as? [String: Any])
        let createAgentImages = try #require(createAgentPrompt["images"] as? [[String: Any]])
        #expect(createAgentImages.count == 1)
        #expect(createAgentImages.first?["url"] as? String == "https://example.com/source-image.png")

        let secondRunBody = try #require(runCreationRequests.first?.httpBody)
        let secondRunJSON = try #require(JSONSerialization.jsonObject(with: secondRunBody) as? [String: Any])
        let secondPrompt = try #require(secondRunJSON["prompt"] as? [String: Any])
        let secondImages = (secondPrompt["images"] as? [[String: Any]]) ?? []
        #expect(secondImages.isEmpty)
    }

    @Test func throwsAPIErrorOnNonSuccessStatus() async throws {
        let client = CursorClient(
            urlSession: FakeURLSession { request in
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
        )

        do {
            _ = try await client.extractDeals(
                imageURL: URL(string: "https://example.com/image.jpg")!,
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
            urlSession: FakeURLSession { request in
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
                imageURL: URL(string: "https://example.com/image.jpg")!,
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
