//Created by Alex Skorulis on 18/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct WebMarkdownGeneratorTests {

    private static let sampleURL = URL(string: "https://example.com/menu")!

    @Test func sendsGetWithUrlQueryParamAndAcceptHeader() async throws {
        let captured = RequestCapture()

        let generator = WebMarkdownGenerator { request in
            captured.request = request
            return "# Example Menu"
        }

        let markdown = try await generator.markdown(for: Self.sampleURL, apiKey: "markdowner-key")

        let request = try #require(captured.request as? MarkdownRequest)
        #expect(request.method == "GET")
        #expect(request.params["url"] == Self.sampleURL.absoluteString)
        #expect(request.headers["Accept"] == "text/plain")
        #expect(request.headers["Authorization"] == "Bearer markdowner-key")
        #expect(markdown == "# Example Menu")
    }

    @Test func omitsAuthorizationWhenApiKeyEmpty() async throws {
        let captured = RequestCapture()

        let generator = WebMarkdownGenerator { request in
            captured.request = request
            return "# Example Menu"
        }

        _ = try await generator.markdown(for: Self.sampleURL)

        let request = try #require(captured.request as? MarkdownRequest)
        #expect(request.headers["Authorization"] == nil)
    }

    @Test func decodesPlainTextResponse() async throws {
        let generator = WebMarkdownGenerator { _ in
            "# Happy Hour\n\n$5 beers"
        }

        let markdown = try await generator.markdown(for: Self.sampleURL, apiKey: "key")
        #expect(markdown == "# Happy Hour\n\n$5 beers")
    }

    @Test func maps429ToRateLimitExceeded() async throws {
        let generator = WebMarkdownGenerator { request in
            let response = HTTPURLResponse(
                url: URL(string: "https://md.dhr.wtf/")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return try request.decode(data: Data("Rate limit exceeded".utf8), response: response)
        }

        do {
            _ = try await generator.markdown(for: Self.sampleURL)
            Issue.record("Expected rate limit error")
        } catch let error as WebMarkdownGeneratorError {
            guard case .rateLimitExceeded = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
    }

    @Test func mapsEmpty200BodyToEmptyContent() async throws {
        let generator = WebMarkdownGenerator { request in
            let response = HTTPURLResponse(
                url: URL(string: "https://md.dhr.wtf/")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return try request.decode(data: Data("   ".utf8), response: response)
        }

        do {
            _ = try await generator.markdown(for: Self.sampleURL)
            Issue.record("Expected empty content error")
        } catch let error as WebMarkdownGeneratorError {
            guard case .emptyContent = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
    }
}

private final class RequestCapture {
    var request: (any HTTPRequest)?
}
