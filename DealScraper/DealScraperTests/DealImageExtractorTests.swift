//  Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

private final class BundleToken {}

struct DealImageExtractorTests {

    @Test func hiveCheeseburgerPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_$10_cheese_burger")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!texts.isEmpty)
        #expect(hasLine("CHEESEBURGER TUESDAYS", in: texts))
        #expect(hasLine("TEN DOLLAR BEEF OR VEGAN", in: texts))
        #expect(hasLine("CHEESEBURGERS WITH CHIPS", in: texts))
        #expect(hasLine("(WITH ANY DRINK PURCHASE)", in: texts))
        #expect(hasLine("EVERY TUES", in: texts))
        #expect(hasLine("DINE IN ONLY", in: texts))
    }

    @Test func hiveBarHappyHourPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_bar_happy_hour")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!texts.isEmpty)
        #expect(hasLine("HAPPY HOUR AT", in: texts))
        #expect(hasLine("$8 SCHOONERS OF RECKLESS", in: texts))
        #expect(hasLine("PALE ALE & LAGER", in: texts))
        #expect(hasLine("$8 WINES, S10 GIN & TONICS", in: texts))
        #expect(hasLine("TUES - THURS 4PM - 6PM / FRI 3PM - 5PM", in: texts))
    }

    @Test func kurrajongRoastPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "kurrajon_roast")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!texts.isEmpty)
        #expect(hasLine("FROM 11:30 TILL SOLD OUT.", in: texts))
        #expect(hasLine("$39PP", in: texts))
        #expect(hasLine("SUNDAY", in: texts))
        #expect(hasLine("ROAST", in: texts))
        #expect(hasLine("ROAST, GRAVY, AND ZERO REGRETS.", in: texts))
    }

    @Test func goatDealsPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "goat_deals")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)

        #expect(!texts.isEmpty)
        #expect(hasLine("GOAT", in: texts))
        #expect(hasLine("WHAT'S ON", in: texts))
        #expect(hasLine("MON STEAK NIGHT", in: texts))
        #expect(hasLine("$25 STEAK + SCHOONER, FREE POOL, HAPPY HOUR 4-6PM", in: texts))
        #expect(hasLine("TUE $20 BURGER + SCHOONER, HAPPY HOUR 4-6PM", in: texts))
        #expect(hasLine("WED HALF-PRICE PIZZA", in: texts))
        #expect(hasLine("HALF PRICE PIZZAS, $10 PINTS OF TPA, BILLY + VEB, HAPPY HOUR 4-6PM", in: texts))
        #expect(hasLine("THU SCHNITZ&BEER", in: texts))
        #expect(hasLine("$20 SCHNITZEL + SCHOONER ALL DAY, HAPPY HOUR 4-6PM", in: texts))
        #expect(hasLine("FRI HAPPY HOUR", in: texts))
        #expect(hasLine("SAT $12 ESPRESSO MARTINIS 6-8PM", in: texts))
        #expect(hasLine("SUN CHICKEN& BEER", in: texts))
        #expect(hasLine("$12 SPITZ + BEER CAN CHICKEN", in: texts))
        #expect(hasLine("FOLLOW US @GOATNEWTOWN", in: texts))
    }

    private func hasLine(_ expected: String, in texts: [String]) -> Bool {
        texts.contains { $0.caseInsensitiveCompare(expected) == .orderedSame }
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
