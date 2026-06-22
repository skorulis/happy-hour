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

        #expect(result.fullMarkdown.contains("BAR MENU"))
        #expect(result.fullMarkdown.contains("SHREDDED KALE BRUSSEL SALAD"))
        #expect(result.fullMarkdown.contains("EGGPLANT MOUSSAKA"))
        #expect(result.fullMarkdown.contains("FIZZ"))
        #expect(result.fullMarkdown.contains("150ml / BT"))
        #expect(result.fullMarkdown.contains("MEMBERS' HAPPY HOUR") || result.fullMarkdown.contains("MEMBERS’ HAPPY HOUR"))
        #expect(result.fullMarkdown.contains("TAP BEERS FROM $6"))
        #expect(result.fullMarkdown.contains("COCKTAILS ALL $21"))

        #expect(result.filteredMarkdown.contains("MEMBERS"))
        #expect(result.filteredMarkdown.contains("TAP BEERS FROM $6"))
        #expect(result.filteredMarkdown.localizedCaseInsensitiveContains("happy hour"))

        #expect(!result.fullMarkdown.contains("14 / 65 TAP BEERS"))
        #expect(!result.fullMarkdown.contains("10 / 45 TOMMY"))
        #expect(!result.fullMarkdown.contains("17 / 78 WINES FROM $6"))

        let fizIndex = try #require(result.fullMarkdown.range(of: "FIZZ")?.lowerBound)
        let mlbtIndex = try #require(result.fullMarkdown.range(of: "150ml / BT")?.lowerBound)
        let membersIndex = try #require(result.fullMarkdown.range(of: "MEMBERS")?.lowerBound)
        #expect(fizIndex < mlbtIndex)
        #expect(mlbtIndex < membersIndex)
    }

    @Test func extractTextFromGlebeDrinksMenu() throws {
        let extractor = PDFTextExtractor()
        let pdfURL = try fixturePDFURL(named: "glebe_drinks_menu")

        let result = try #require(extractor.extractText(from: pdfURL))
        
        print(result.fullMarkdown)
        
        let happyHour = """
        # Members' Happy Hour

        Monday to Friday: 4pm—6pm
        Tap beers from $6 / pints from $9
        Glasses of wine from $6
        Aperol spritz $13
        Espresso martini $15
        """
        
        #expect(result.fullMarkdown.contains(happyHour))

        #expect(result.fullMarkdown.contains("COCKTAILS"))
        #expect(result.fullMarkdown.contains("all $20"))
        #expect(result.fullMarkdown.contains("Members' Happy Hour"))
        #expect(result.fullMarkdown.contains("History of the Glebe Hotel"))
        #expect(result.fullMarkdown.contains("AROMATIC WHITES"))
        #expect(result.fullMarkdown.contains("150ml Bottle"))
        #expect(result.fullMarkdown.contains("VODKA"))
        #expect(result.fullMarkdown.contains("30ml"))
        #expect(result.filteredMarkdown.contains("Members' Happy Hour"))
        #expect(result.filteredMarkdown.contains("Monday to Friday: 4pm—6pm"))
        #expect(result.filteredMarkdown.contains("Tap beers from $6 / pints from $9"))
        #expect(result.filteredMarkdown.contains("Espresso martini $15"))
        #expect(!result.filteredMarkdown.contains("History of the Glebe Hotel"))
        #expect(!result.filteredMarkdown.contains("AROMATIC WHITES"))
        #expect(!result.filteredMarkdown.contains("VODKA"))
        #expect(result.filteredMarkdown.contains("#"))
        #expect(result.filteredMarkdown.contains("\n\n"))
        #expect(!result.fullMarkdown.contains("COCKTAILSall"))
        #expect(!result.fullMarkdown.contains("TAP BEER & CIDER Schooner"))
        let cocktailsIndex = try #require(result.fullMarkdown.range(of: "COCKTAILS")?.lowerBound)
        let tapBeerIndex = try #require(result.fullMarkdown.range(of: "TAP BEER & CIDER")?.lowerBound)
        let leftColumnEnd = try #require(result.fullMarkdown.range(of: "SOFT / MINERALS / JUICES")?.lowerBound)
        #expect(cocktailsIndex < leftColumnEnd)
        #expect(leftColumnEnd < tapBeerIndex)
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
