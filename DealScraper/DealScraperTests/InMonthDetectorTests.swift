//Created by Alex Skorulis on 27/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct InMonthDetectorTests {

    private let july2026 = Self.date(year: 2026, month: 7, day: 27)
    private let december2026 = Self.date(year: 2026, month: 12, day: 15)

    @Test func rejectsStaleInMonthRelativeToNow() {
        #expect(InMonthDetector.isMatch(in: ["IN DECEMBER"], now: july2026))
        #expect(InMonthDetector.isMatch(in: ["In March"], now: july2026))
        #expect(InMonthDetector.isMatch(in: ["in jan"], now: july2026))
    }

    @Test func allowsCurrentAndNextMonth() {
        #expect(!InMonthDetector.isMatch(in: ["IN JULY"], now: july2026))
        #expect(!InMonthDetector.isMatch(in: ["In August"], now: july2026))
        #expect(!InMonthDetector.isMatch(in: ["in aug"], now: july2026))
    }

    @Test func wrapsNextMonthFromDecemberToJanuary() {
        #expect(!InMonthDetector.isMatch(in: ["IN DECEMBER"], now: december2026))
        #expect(!InMonthDetector.isMatch(in: ["In January"], now: december2026))
        #expect(InMonthDetector.isMatch(in: ["IN FEBRUARY"], now: december2026))
        #expect(InMonthDetector.isMatch(in: ["In July"], now: december2026))
    }

    @Test func ignoresTextWithoutInMonthPhrase() {
        #expect(!InMonthDetector.isMatch(in: ["thursday local night", "$20 JUGS"], now: july2026))
        #expect(!InMonthDetector.isMatch(in: ["December specials every Thursday"], now: july2026))
        #expect(!InMonthDetector.isMatch(in: ["into December"], now: july2026))
    }

    @Test func matchesGreatNorthernLocalsThursdayPoster() {
        #expect(
            InMonthDetector.isMatch(
                in: [
                    "thursday local night",
                    "$20 JUGS",
                    "$1 POOL",
                    "$7 SPIRITS",
                    "$18 PIZZAS",
                    "IN DECEMBER",
                    "7pm til close",
                    "loyalty members only",
                ],
                now: july2026
            )
        )
    }

    @Test func allowedMonthsAreCurrentAndNext() {
        #expect(InMonthDetector.allowedMonths(relativeTo: july2026) == [7, 8])
        #expect(InMonthDetector.allowedMonths(relativeTo: december2026) == [12, 1])
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components)!
    }
}
