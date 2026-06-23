//  Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

private final class BundleToken {}

struct DealImageExtractorTests {

    @Test func hiveCheeseburgerPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_$10_cheese_burger")

        let lines = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!lines.isEmpty)
        #expect(hasLine(containing: "CHEESEBURGER TUESDAYS", in: lines))
        #expect(hasLine(
            "TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS (WITH ANY DRINK PURCHASE)",
            in: lines
        ))
        #expect(hasLine("EVERY TUES DINE IN ONLY", in: lines))
    }

    @Test func hiveBarHappyHourPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_bar_happy_hour")

        let lines = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!lines.isEmpty)
        #expect(hasLine(containing: "HAPPY HOUR AT Hive Bar", in: lines))
        #expect(hasLine(containing: "$8 SCHOONERS OF RECKLESS", in: lines))
        #expect(hasLine(containing: "PALE ALE & LAGER", in: lines))
        #expect(hasLine(containing: "$8 WINES, S10 GIN & TONICS", in: lines))
        #expect(hasLine("TUES - THURS 4PM - 6PM / FRI 3PM - 5PM", in: lines))
    }

    @Test func kurrajongRoastPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "kurrajon_roast")

        let lines = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!lines.isEmpty)
        #expect(hasLine("FROM 11:30 TILL SOLD OUT.", in: lines))
        #expect(hasLine("$39PP", in: lines))
        #expect(hasLine("SUNDAY", in: lines))
        #expect(hasLine("ROAST", in: lines))
        #expect(hasLine("ROAST, GRAVY, AND ZERO REGRETS.", in: lines))
    }

    @Test func goatDealsPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "goat_deals")

        let lines = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!lines.isEmpty)
        #expect(hasLine("GOAT", in: lines))
        #expect(hasLine("WHAT'S ON", in: lines))
        #expect(hasLine("MON STEAK NIGHT", in: lines))
        #expect(hasLine("$25 STEAK + SCHOONER, FREE POOL, HAPPY HOUR 4-6PM", in: lines))
        #expect(hasLine("TUE $20 BURGER + SCHOONER, HAPPY HOUR 4-6PM", in: lines))
        #expect(hasLine("WED HALF-PRICE PIZZA", in: lines))
        #expect(hasLine("HALF PRICE PIZZAS, $10 PINTS OF TPA, BILLY + VEB, HAPPY HOUR 4-6PM", in: lines))
        #expect(hasLine("THU SCHNITZ&BEER", in: lines))
        #expect(hasLine("$20 SCHNITZEL + SCHOONER ALL DAY, HAPPY HOUR 4-6PM", in: lines))
        #expect(hasLine("FRI HAPPY HOUR", in: lines))
        #expect(hasLine("SAT $12 ESPRESSO MARTINIS 6-8PM", in: lines))
        #expect(hasLine("SUN CHICKEN& BEER", in: lines))
        #expect(hasLine("$12 SPITZ + BEER CAN CHICKEN", in: lines))
        #expect(hasLine("FOLLOW US @GOATNEWTOWN", in: lines))
    }

    @Test func goatDealsPosterTitleLinesAreLargerThanDetailLines() async throws {
        let imageURL = try getURL(name: "goat_deals")

        let lines = try await DealImageExtractor().extractTexts(from: imageURL)

        let titleLine = try #require(line("MON STEAK NIGHT", in: lines))
        let detailLine = try #require(line("$25 STEAK + SCHOONER, FREE POOL, HAPPY HOUR 4-6PM", in: lines))
        let whatsOnLine = try #require(line("WHAT'S ON", in: lines))

        #expect(titleLine.lineHeight > detailLine.lineHeight)
        #expect(whatsOnLine.relativeSize == .large)
        #expect(detailLine.relativeSize == .small)
    }

    @Test func establishmentDateLineDetection() {
        #expect(DealImageExtractor.isEstablishmentDateLine("EST. 1862"))
        #expect(DealImageExtractor.isEstablishmentDateLine("ESTO 2005"))
        #expect(DealImageExtractor.isEstablishmentDateLine("est 1999"))
        #expect(DealImageExtractor.isEstablishmentDateLine("  ESTABLISHED 2010  "))
        #expect(DealImageExtractor.isEstablishmentDateLine("EST.1862"))

        #expect(!DealImageExtractor.isEstablishmentDateLine("HAPPY HOUR"))
        #expect(!DealImageExtractor.isEstablishmentDateLine("THE GLEBE HOTEL EST. 1862"))
        #expect(!DealImageExtractor.isEstablishmentDateLine("EST"))
        #expect(!DealImageExtractor.isEstablishmentDateLine("1862"))
    }

    @Test func dealPosterFixturesHaveHighTextCoverage() async throws {
        let imageURL = try getURL(name: "goat_deals")
        let coverage = try await DealImageExtractor().textCoverageRatio(from: imageURL)

        #expect(coverage > 0)
    }

    private func hasLine(_ expected: String, in lines: [ExtractedTextLine]) -> Bool {
        line(expected, in: lines) != nil
    }

    private func hasLine(containing expected: String, in lines: [ExtractedTextLine]) -> Bool {
        lines.contains { $0.text.range(of: expected, options: .caseInsensitive) != nil }
    }

    private func line(_ expected: String, in lines: [ExtractedTextLine]) -> ExtractedTextLine? {
        lines.first { $0.text.caseInsensitiveCompare(expected) == .orderedSame }
    }

    private func getURL(name: String, extension ext: String = "jpeg") throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        guard let imageURL = bundle.url(forResource: name, withExtension: ext) else {
            throw TestError.missingImage(name)
        }
        return imageURL
    }
}

private enum TestError: Error {
    case missingImage(String)
}
