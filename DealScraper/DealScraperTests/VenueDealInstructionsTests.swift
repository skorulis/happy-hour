//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueDealInstructionsTests {

    @Test func usesMarkdownContextWhenMaterialHasMarkdown() {
        let material = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 1,
            url: URL(string: "https://example.com/specials")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .webpage,
            pngData: nil,
            markdown: "# Happy Hour\n\n$5 beers"
        )

        let instructions = VenueDealInstructions.dealExtraction(for: material)
        #expect(instructions.contains(VenueDealInstructions.markdownSourceContext))

        let preamble = VenueDealInstructions.promptPreamble(venueName: "Test Pub", material: material)
        #expect(preamble.contains("webpage markdown"))
        #expect(preamble.contains(VenueDealInstructions.markdownExtractionTask))
    }

    @Test func usesWebpageLinkContextWhenMaterialHasNoMarkdown() {
        let material = VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 1,
            url: URL(string: "https://example.com/specials")!,
            sourceURL: URL(string: "https://example.com/specials")!,
            type: .webpage,
            pngData: nil,
            markdown: nil
        )

        let instructions = VenueDealInstructions.dealExtraction(for: material)
        #expect(instructions.contains(VenueDealInstructions.webpageSourceContext))

        let preamble = VenueDealInstructions.promptPreamble(venueName: "Test Pub", material: material)
        #expect(preamble.contains("webpage link"))
        #expect(preamble.contains(VenueDealInstructions.webpageExtractionTask))
    }
}
