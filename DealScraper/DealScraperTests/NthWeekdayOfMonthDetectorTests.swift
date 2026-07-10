//Created by Alex Skorulis on 10/7/2026.

import Testing
@testable import DealScraper

struct NthWeekdayOfMonthDetectorTests {

    @Test func matchesStandardOrdinalInDetails() {
        #expect(
            NthWeekdayOfMonthDetector.isMatch(
                title: "Steak Night",
                details: ["First Tuesday of each Month"],
                conditions: [],
                days: []
            )
        )
    }

    @Test func matchesSlashNotationInDetails() {
        #expect(
            NthWeekdayOfMonthDetector.isMatch(
                title: nil,
                details: ["(First/Second/Third/Fourth/Last) Tuesday of (each/every/the) Month"],
                conditions: [],
                days: []
            )
        )
    }

    @Test func matchesOrdinalInDays() {
        #expect(
            NthWeekdayOfMonthDetector.isMatch(
                title: "Special",
                details: ["$10 meals"],
                conditions: [],
                days: ["Last Friday of the month"]
            )
        )
    }

    @Test func matchesNumericOrdinalInConditions() {
        #expect(
            NthWeekdayOfMonthDetector.isMatch(
                title: "Wine Night",
                details: [],
                conditions: ["2nd Wed of every month"],
                days: ["Wednesday"]
            )
        )
    }

    @Test func rejectsEveryWeekdaySchedule() {
        #expect(
            !NthWeekdayOfMonthDetector.isMatch(
                title: "Happy Hour",
                details: ["Every Tuesday 4PM - 6PM"],
                conditions: [],
                days: ["Tuesday"]
            )
        )
    }

    @Test func rejectsPlainTuesdaySchedule() {
        #expect(
            !NthWeekdayOfMonthDetector.isMatch(
                title: "Taco Tuesday",
                details: ["$5 tacos"],
                conditions: [],
                days: ["EVERY TUES"]
            )
        )
    }

    @Test func rejectsNormalWeeklyHappyHour() {
        #expect(
            !NthWeekdayOfMonthDetector.isMatch(
                title: "Happy Hour",
                details: ["$8 wines", "HAPPY HOUR TUES - THURS 4PM - 6PM"],
                conditions: [],
                days: ["Tuesday", "Wednesday", "Thursday"]
            )
        )
    }
}
