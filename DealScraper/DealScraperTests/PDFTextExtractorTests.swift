//Created by Alex Skorulis on 20/6/2026.

import Foundation
import PDFKit
import Testing
@testable import DealScraper

@Suite(.serialized)
struct PDFTextExtractorTests {

    @Test func extractTextFromGlebeBarMenu() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_bar_menu")

        let result = try #require(extractor.extractText(from: pdfURL))

        #expect(result.fullText.contains("BAR MENU"))
        #expect(result.fullText.contains("SHREDDED KALE BRUSSEL SALAD"))
        #expect(result.fullText.contains("EGGPLANT MOUSSAKA"))
        #expect(result.fullText.contains("FIZZ"))
        #expect(result.fullText.contains("150ml / BT"))
        #expect(result.fullText.contains("MEMBERS' HAPPY HOUR") || result.fullText.contains("MEMBERS\u{2019} HAPPY HOUR"))
        #expect(result.fullText.contains("TAP BEERS FROM $6"))
        #expect(result.fullText.contains("COCKTAILS ALL $21"))

        #expect(result.filteredText.contains("MEMBERS"))
        #expect(result.filteredText.contains("TAP BEERS FROM $6"))
        #expect(result.filteredText.localizedCaseInsensitiveContains("happy hour"))
    }

    @Test func extractTextFromGlebeDrinksMenu() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_drinks_menu")

        let result = try #require(extractor.extractText(from: pdfURL))

        #expect(result.fullText.contains("COCKTAILS"))
        #expect(result.fullText.contains("all $20"))
        #expect(result.fullText.contains("Members' Happy Hour"))
        #expect(result.fullText.contains("History of the Glebe Hotel"))
        #expect(result.fullText.contains("AROMATIC WHITES"))
        #expect(result.fullText.contains("150ml Bottle"))
        #expect(result.fullText.contains("VODKA"))
        #expect(result.fullText.contains("30ml"))
        #expect(result.filteredText.contains("Members' Happy Hour"))
        #expect(result.filteredText.contains("Monday to Friday: 4pm—6pm"))
        #expect(result.filteredText.contains("Tap beers from $6 / pints from $9"))
        #expect(result.filteredText.contains("Espresso martini $15"))
        #expect(!result.filteredText.contains("History of the Glebe Hotel"))
        #expect(!result.filteredText.contains("AROMATIC WHITES"))
        #expect(!result.filteredText.contains("VODKA"))
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
