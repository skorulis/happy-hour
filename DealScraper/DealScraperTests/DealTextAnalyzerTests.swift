//  Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTextAnalyzerTests {

    private static let hiveCheeseburgerTexts = [
        "TEN",
        "DOLLAR",
        "CHEESEBURGER TUESDAYS",
        "TEN DOLLAR BEEF OR VEGAN",
        "CHEESEBURGERS WITH CHIPS",
        "(WITH ANY DRINK PURCHASE)",
        "EVERY TUES",
        "DINE IN ONLY",
        "Hive Bar",
        "ESTO 2009",
        "WWW.THEHIVEBAR.COM.AU",
    ]

    private static let hiveHappyHourTexts = [
        "HAPPY HOUR AT",
        "Hive Bar",
        "ESTE 2009",
        "$8 SCHOONERS OF RECKLESS",
        "PALE ALE & LAGER",
        "$8 WINES, S10 GIN & TONICS",
        "$15 HOUSE SPRITZERS",
        "TUES - THURS 4PM - 6PM / FRI 3PM - 5PM",
        "RSA APPLIES / DRINK RESPONSIBLY / NOT AVAILABLE ON PUBLIC HOLIDAYS",
    ]

    private static let kurrajongRoastTexts = [
        "FROM 11:30 TILL SOLD OUT.",
        "$39PP",
        "SUNDAY",
        "ROAST",
        "KURRAJONG HOTEL",
        "VUV",
        "ROAST, GRAVY, AND ZERO REGRETS.",
    ]

    @Test func hiveCheeseburgerPosterExtractsDeal() async throws {
        let texts = Self.hiveCheeseburgerTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)
        let deal = try #require(results.first)
        #expect(deal.allTexts == texts)
        
        print(deal)

        let combinedDeals = results.flatMap(\.deals).joined(separator: " ").lowercased()
        #expect(combinedDeals.contains("cheeseburger"))
        #expect(combinedDeals.contains("dollar") || combinedDeals.contains("$10") || combinedDeals.contains("ten"))
        #expect(results.flatMap(\.days).contains(.tuesday))
    }

    @Test func hiveBarHappyHourPosterExtractsDeal() async throws {
        let texts = Self.hiveHappyHourTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)
        let deal = try #require(results.first)
        #expect(deal.allTexts == texts)

        let combinedDeals = results.flatMap(\.deals).joined(separator: " ").lowercased()
        #expect(combinedDeals.contains("happy hour") || combinedDeals.contains("schooner") || combinedDeals.contains("pale ale"))
        #expect(results.flatMap(\.days).contains(.tuesday))
        #expect(results.flatMap(\.days).contains(.thursday))
        #expect(Self.containsTime(from: 960, in: results.flatMap(\.times)))
    }

    @Test func kurrajongRoastPosterExtractsDeal() async throws {
        let texts = Self.kurrajongRoastTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)
        let deal = try #require(results.first)
        #expect(deal.allTexts == texts)

        let combinedDeals = results.flatMap(\.deals).joined(separator: " ").lowercased()
        let combinedTexts = texts.joined(separator: " ").lowercased()
        #expect(combinedDeals.contains("roast") || combinedTexts.contains("roast"))
        #expect(combinedDeals.contains("$39") || combinedDeals.contains("39"))
        #expect(results.flatMap(\.days).contains(.sunday))
        #expect(Self.containsTime(from: 690, in: results.flatMap(\.times)))
    }

    private static func containsTime(from minutes: Int, in times: [DealTime]) -> Bool {
        times.contains { time in
            switch time {
            case .from(let value):
                return value == minutes
            case .between(let start, _):
                return start == minutes
            case .allDay:
                return false
            }
        }
    }
}
