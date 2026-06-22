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

    @Test func glebeBarMenuWinePageKeepsPricesWithWineList() throws {
        let page = try glebeBarMenuPage(index: 1)
        let extractor = PDFLayoutExtractor()
        let lineTexts = extractor.lines(from: page).map { extractor.lineText(from: $0) }

        let fizIndex = try #require(lineTexts.firstIndex(where: { $0 == "FIZZ" }))
        let mlbtIndex = try #require(lineTexts.firstIndex(where: { $0.contains("150ml / BT") }))
        let firstFizzPriceIndex = try #require(lineTexts.firstIndex(where: { $0 == "10 / 45" }))
        let membersIndex = try #require(lineTexts.firstIndex(where: { $0.contains("MEMBERS") }))
        let tapBeersIndex = try #require(lineTexts.firstIndex(where: { $0.contains("TAP BEERS FROM $6") }))

        #expect(fizIndex < mlbtIndex)
        #expect(mlbtIndex < firstFizzPriceIndex)
        #expect(firstFizzPriceIndex < membersIndex)
        #expect(membersIndex < tapBeersIndex)

        #expect(!lineTexts.contains(where: { $0.contains("14 / 65 TAP BEERS") }))
        #expect(!lineTexts.contains(where: { $0.contains("10 / 45 TOMMY") }))
        #expect(!lineTexts.contains(where: { $0.contains("17 / 78 WINES FROM $6") }))
        #expect(!lineTexts.contains(where: { $0.contains("12 / 54 ESPRESSO MARTINI") }))
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

    private func glebeBarMenuPage(index: Int) throws -> PDFPage {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: "glebe_bar_menu", withExtension: "pdf"),
              let document = PDFDocument(url: url),
              let page = document.page(at: index)
        else {
            throw NSError(domain: "PDFLayoutExtractorTests", code: 2)
        }
        return page
    }
}

private final class BundleToken {}
