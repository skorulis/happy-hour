//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueDealInstructionsTests {

    @Test func usesMarkdownContextWhenMaterialHasMarkdown() {
        let material = VenueDealSourceMaterial.fixture(markdown: "# Happy Hour\n\n$5 beers")

        let instructions = VenueDealInstructions.dealExtraction(for: material)
        #expect(instructions.contains(VenueDealInstructions.markdownSourceContext))

        let preamble = VenueDealInstructions.promptPreamble(venueName: "Test Pub", material: material)
        #expect(preamble.contains("webpage markdown"))
        #expect(preamble.contains(VenueDealInstructions.markdownExtractionTask))
    }

    @Test func usesWebpageLinkContextWhenMaterialHasNoMarkdown() {
        let material = VenueDealSourceMaterial.fixture()

        let instructions = VenueDealInstructions.dealExtraction(for: material)
        #expect(instructions.contains(VenueDealInstructions.webpageSourceContext))

        let preamble = VenueDealInstructions.promptPreamble(venueName: "Test Pub", material: material)
        #expect(preamble.contains("webpage link"))
        #expect(preamble.contains(VenueDealInstructions.webpageExtractionTask))
    }

    @Test func usesPDFContextWhenMaterialIsPDF() {
        let material = VenueDealSourceMaterial.fixture(type: .pdf, markdown: "Happy Hour\n\nMonday happy hour 4pm to 6pm")

        let instructions = VenueDealInstructions.dealExtraction(for: material)
        #expect(instructions.contains(VenueDealInstructions.pdfSourceContext))
        #expect(!instructions.contains(VenueDealInstructions.markdownSourceContext))

        let preamble = VenueDealInstructions.promptPreamble(venueName: "Test Pub", material: material)
        #expect(preamble.contains("PDF text"))
        #expect(preamble.contains(VenueDealInstructions.pdfExtractionTask))
    }
}
