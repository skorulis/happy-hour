//  Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealHoursTests {

    @Test func parsesExplicitPMTime() {
        #expect(DealHours.toMinutes(string: "4 PM") == 960)
        #expect(DealHours.toMinutes(string: "4pm") == 960)
        #expect(DealHours.toMinutes(string: "  4 pm  ") == 960)
    }

    @Test func parsesExplicitAMTime() {
        #expect(DealHours.toMinutes(string: "7 AM") == 420)
        #expect(DealHours.toMinutes(string: "9am") == 540)
    }

    @Test func parsesTimeWithMinutes() {
        #expect(DealHours.toMinutes(string: "4:30 PM") == 990)
        #expect(DealHours.toMinutes(string: "7:15am") == 435)
    }

    @Test func guessesAMWhenOnlyAMFitsInRange() {
        #expect(DealHours.toMinutes(string: "11:30") == 690)
        #expect(DealHours.toMinutes(string: "10:00") == 600)
        #expect(DealHours.toMinutes(string: "9:30") == 570)
    }

    @Test func guessesPMWhenOnlyPMFitsInRange() {
        #expect(DealHours.toMinutes(string: "4:00") == 960)
        #expect(DealHours.toMinutes(string: "1:30") == 810)
    }

    @Test func guessesNoonForAmbiguousMidday() {
        #expect(DealHours.toMinutes(string: "12:00") == 720)
    }

    @Test func prefersPMWhenBothAMAndPMFitInRange() {
        #expect(DealHours.toMinutes(string: "7:00") == 1140)
        #expect(DealHours.toMinutes(string: "8:30") == 1230)
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(DealHours.toMinutes(string: "not a time") == nil)
        #expect(DealHours.toMinutes(string: "") == nil)
        #expect(DealHours.toMinutes(string: "25:00") == nil)
        #expect(DealHours.toMinutes(string: "4:99") == nil)
    }

    @Test func returnsExplicitTimeEvenWhenOutsideGuessRange() {
        #expect(DealHours.toMinutes(string: "11:30 PM") == 1410)
        #expect(DealHours.toMinutes(string: "3:00 AM") == 180)
    }

    @Test func parseSingleTime() {
        #expect(DealHours.parse("4 PM") == .from(960))
        #expect(DealHours.parse("11:30") == .from(690))
    }

    @Test func parseTimeRange() {
        #expect(DealHours.parse("4 PM - 6 PM") == .between(960, 1080))
        #expect(DealHours.parse("4 PM-6 PM") == .between(960, 1080))
        #expect(DealHours.parse("4 PM to 6 PM") == .between(960, 1080))
    }

    @Test func parseReturnsNilForUnparseableInput() {
        #expect(DealHours.parse("") == nil)
        #expect(DealHours.parse("not a time") == nil)
    }

    @Test func fromStringParsesFromPrefix() {
        #expect(DealHours.fromString("from 11AM") == .from(660))
        #expect(DealHours.fromString("FROM 11:30") == .from(690))
    }

    @Test func fromStringParsesTimeRange() {
        #expect(DealHours.fromString("4PM - 6PM") == .between(960, 1080))
        #expect(DealHours.fromString("4 PM - 6 PM") == .between(960, 1080))
    }

    @Test func fromStringReturnsNilForUnparseableInput() {
        #expect(DealHours.fromString("") == nil)
        #expect(DealHours.fromString("from") == nil)
        #expect(DealHours.fromString("not a time") == nil)
    }
}
