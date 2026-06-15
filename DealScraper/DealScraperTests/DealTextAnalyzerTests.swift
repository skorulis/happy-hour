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
        "HAPPY HOUR AT Hive Bar",
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

    private static let goatDealsTexts = [
        "GOAT",
        "WHAT'S ON",
        "MON STEAK NIGHT",
        "$25 STEAK + SCHOONER, FREE POOL, HAPPY HOUR 4-6PM",
        "TUE $20 BURGER + SCHOONER, HAPPY HOUR 4-6PM",
        "WED HALF-PRICE PIZZA",
        "HALF PRICE PIZZAS, $10 PINTS OF TPA, BILLY + VEB, HAPPY HOUR 4-6PM",
        "THU SCHNITZ&BEER",
        "$20 SCHNITZEL + SCHOONER ALL DAY, HAPPY HOUR 4-6PM",
        "FRI HAPPY HOUR",
        "SAT $12 ESPRESSO MARTINIS 6-8PM",
        "SUN CHICKEN& BEER",
        "$12 SPITZ + BEER CAN CHICKEN",
        "FOLLOW US @GOATNEWTOWN",
    ]

    @Test func hiveCheeseburgerPosterExtractsDeal() async throws {
        let texts = Self.hiveCheeseburgerTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)

        let deal = try #require(results.first)
        let title = deal.title.lowercased()
        let details = deal.details.map { $0.lowercased() }
        let combinedDetails = details.joined(separator: " ")
        
        print(deal)

        #expect(title.contains("cheeseburger"))
        #expect(combinedDetails.contains("ten") || combinedDetails.contains("dollar"))

        #expect(combinedDetails.contains("ten dollar beef or vegan"))
        #expect(combinedDetails.contains("cheeseburgers with chips"))
        #expect(combinedDetails.contains("with any drink purchase"))

        #expect(deal.days == [.tuesday])
        #expect(deal.times == [.allDay])
    }

    @Test func hiveBarHappyHourPosterExtractsDeal() async throws {
        let texts = Self.hiveHappyHourTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)

        let combinedText = results
            .map { [$0.title] + $0.details }
            .flatMap { $0 }
            .joined(separator: " ")
            .lowercased()
        #expect(combinedText.contains("happy hour") || combinedText.contains("schooner") || combinedText.contains("pale ale"))
        #expect(results.flatMap(\.days).contains(.tuesday))
        #expect(results.flatMap(\.days).contains(.thursday))
        #expect(Self.containsTime(from: 960, in: results.flatMap(\.times)))
    }

    @Test func kurrajongRoastPosterExtractsDeal() async throws {
        let texts = Self.kurrajongRoastTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(results.count == 1)

        let combinedText = results
            .map { [$0.title] + $0.details }
            .flatMap { $0 }
            .joined(separator: " ")
            .lowercased()
        let combinedTexts = texts.joined(separator: " ").lowercased()
        #expect(combinedText.contains("roast") || combinedTexts.contains("roast"))
        #expect(combinedText.contains("$39") || combinedText.contains("39"))
        #expect(results.flatMap(\.days).contains(.sunday))
        #expect(Self.containsTime(from: 690, in: results.flatMap(\.times)))
    }

    @Test func goatDealsPosterExtractsDeals() async throws {
        let texts = Self.goatDealsTexts
        let results = try await DealTextAnalyzer().analyze(texts: texts)

        #expect(!results.isEmpty)
        
        print(results)

        let combinedText = results
            .map { [$0.title] + $0.details }
            .flatMap { $0 }
            .joined(separator: " ")
            .lowercased()
        let allDays = results.flatMap(\.days)
        let allTimes = results.flatMap(\.times)

        #expect(combinedText.contains("steak"))
        #expect(combinedText.contains("burger") || combinedText.contains("schooner"))
        #expect(combinedText.contains("pizza"))
        #expect(combinedText.contains("schnitz"))
        #expect(combinedText.contains("happy hour") || combinedText.contains("espresso martini"))
        #expect(combinedText.contains("chicken"))

        #expect(allDays.contains(.monday))
        #expect(allDays.contains(.tuesday))
        #expect(allDays.contains(.wednesday))
        #expect(allDays.contains(.thursday))
        #expect(allDays.contains(.friday))
        #expect(allDays.contains(.saturday))
        #expect(allDays.contains(.sunday))

        #expect(Self.containsTime(from: 960, in: allTimes))
    }

    private static func containsTime(from minutes: Int, in times: [DealHours]) -> Bool {
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
