//Created by Alex Skorulis on 20/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct PDFTextExtractorTests {

    @Test func extractTextFromGlebeDrinksMenu() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_drinks_menu")

        let result = try #require(extractor.extractText(from: pdfURL))

        #expect(result.fullText.contains("COCKTAILS all $20"))
        #expect(result.fullText.contains("Members' Happy Hour"))
        #expect(result.fullText.contains("History of the Glebe Hotel"))
        #expect(result.filteredText.contains("Members' Happy Hour"))
        #expect(result.filteredText.contains("Monday to Friday: 4pm—6pm"))
        #expect(result.filteredText.contains("Tap beers from $6 / pints from $9"))
        #expect(!result.filteredText.contains("History of the Glebe Hotel"))
    }

    @Test func extractTextIncludesAllPagesInFullText() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_drinks_menu")

        let result = try #require(extractor.extractText(from: pdfURL))

        #expect(result.fullText.contains("COCKTAILS all $20"))
        #expect(result.fullText.contains("AROMATIC WHITES 150ml Bottle"))
        #expect(result.fullText.contains("VODKA 30ml"))
        #expect(result.fullText.contains("History of the Glebe Hotel"))
    }

    @Test func extractTextFiltersToDealKeywordPages() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_drinks_menu")

        let result = try #require(extractor.extractText(from: pdfURL))

        #expect(result.filteredText.contains("Espresso martini $15"))
        #expect(!result.filteredText.contains("AROMATIC WHITES 150ml Bottle"))
        #expect(!result.filteredText.contains("VODKA 30ml"))
    }

    private func fixturePDFURL(named name: String) throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "pdf") else {
            throw NSError(domain: "PDFTextExtractorTests", code: 1)
        }
        return url
    }
}

private final class BundleToken {}
