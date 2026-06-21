//Created by Alex Skorulis on 22/6/2026.

import Foundation
import PDFKit
import Testing
@testable import DealScraper

@Suite(.serialized)
struct PDFLayoutExtractorTests {

    @Test func glebeMenuPageZeroReadsColumnsInOrder() throws {
        let page = try glebePage(index: 0)
        let extractor = PDFLayoutExtractor()
        let lineTexts = extractor.lines(from: page).map { extractor.lineText(from: $0) }

        let cocktailsIndex = try #require(lineTexts.firstIndex(where: { $0.contains("COCKTAILS") }))
        let softIndex = try #require(lineTexts.firstIndex(where: { $0.contains("SOFT / MINERALS / JUICES") }))
        let tapBeerIndex = try #require(lineTexts.firstIndex(where: { $0.contains("TAP BEER & CIDER") }))
        let schoonerIndex = try #require(lineTexts.firstIndex(where: { $0.contains("Schooner / Pint / Jug") }))

        #expect(cocktailsIndex < softIndex)
        #expect(softIndex < tapBeerIndex)
        #expect(tapBeerIndex < schoonerIndex)
        #expect(!lineTexts.contains(where: { $0.contains("COCKTAILSall") }))
    }

    private func glebePage(index: Int) throws -> PDFPage {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: "glebe_drinks_menu", withExtension: "pdf"),
              let document = PDFDocument(url: url),
              let page = document.page(at: index)
        else {
            throw NSError(domain: "PDFLayoutExtractorTests", code: 1)
        }
        return page
    }
}

private final class BundleToken {}
