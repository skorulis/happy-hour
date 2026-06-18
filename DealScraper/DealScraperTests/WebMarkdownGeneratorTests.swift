//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

@MainActor
struct WebMarkdownGeneratorTests {

    @Test func passesHTMLToConverter() async throws {
        let generator = WebMarkdownGenerator()

        let markdown = try await generator.markdown(from: "<h1>Example Menu</h1>")
        #expect(markdown == "# Example Menu")
    }

    @Test func returnsConvertedMarkdown() async throws {
        let generator = WebMarkdownGenerator()

        let markdown = try await generator.markdown(from: "<h1>Happy Hour</h1>")
        #expect(markdown == "# Happy Hour")
    }

    @Test func throwsOnEmptyHTML() async throws {
        let generator = WebMarkdownGenerator()

        do {
            _ = try await generator.markdown(from: "   ")
            Issue.record("Expected empty content error")
        } catch let error as WebMarkdownGeneratorError {
            guard case .emptyContent = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
    }

    @Test func throwsWhenConverterReturnsEmptyMarkdown() async throws {
        let generator = WebMarkdownGenerator()

        do {
            _ = try await generator.markdown(from: "")
            Issue.record("Expected empty content error")
        } catch let error as WebMarkdownGeneratorError {
            guard case .emptyContent = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
    }
}
