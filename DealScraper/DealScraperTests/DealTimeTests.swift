//  Created by Alexander Skorulis on 14/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTimeTests {

    @Test func parsesExplicitPMTime() {
        #expect(DealTime.toMinutes(string: "4 PM") == 960)
        #expect(DealTime.toMinutes(string: "4pm") == 960)
        #expect(DealTime.toMinutes(string: "  4 pm  ") == 960)
    }

    @Test func parsesExplicitAMTime() {
        #expect(DealTime.toMinutes(string: "7 AM") == 420)
        #expect(DealTime.toMinutes(string: "9am") == 540)
    }

    @Test func parsesTimeWithMinutes() {
        #expect(DealTime.toMinutes(string: "4:30 PM") == 990)
        #expect(DealTime.toMinutes(string: "7:15am") == 435)
    }

    @Test func guessesAMWhenOnlyAMFitsInRange() {
        #expect(DealTime.toMinutes(string: "11:30") == 690)
        #expect(DealTime.toMinutes(string: "10:00") == 600)
        #expect(DealTime.toMinutes(string: "9:30") == 570)
    }

    @Test func guessesPMWhenOnlyPMFitsInRange() {
        #expect(DealTime.toMinutes(string: "4:00") == 960)
        #expect(DealTime.toMinutes(string: "1:30") == 810)
    }

    @Test func guessesNoonForAmbiguousMidday() {
        #expect(DealTime.toMinutes(string: "12:00") == 720)
    }

    @Test func prefersPMWhenBothAMAndPMFitInRange() {
        #expect(DealTime.toMinutes(string: "7:00") == 1140)
        #expect(DealTime.toMinutes(string: "8:30") == 1230)
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(DealTime.toMinutes(string: "not a time") == nil)
        #expect(DealTime.toMinutes(string: "") == nil)
        #expect(DealTime.toMinutes(string: "25:00") == nil)
        #expect(DealTime.toMinutes(string: "4:99") == nil)
    }

    @Test func returnsExplicitTimeEvenWhenOutsideGuessRange() {
        #expect(DealTime.toMinutes(string: "11:30 PM") == 1410)
        #expect(DealTime.toMinutes(string: "3:00 AM") == 180)
    }

    @Test func parseSingleTime() {
        #expect(DealTime.parse("4 PM") == .from(960))
        #expect(DealTime.parse("11:30") == .from(690))
    }

    @Test func parseTimeRange() {
        #expect(DealTime.parse("4 PM - 6 PM") == .between(960, 1080))
        #expect(DealTime.parse("4 PM-6 PM") == .between(960, 1080))
        #expect(DealTime.parse("4 PM to 6 PM") == .between(960, 1080))
    }

    @Test func parseReturnsNilForUnparseableInput() {
        #expect(DealTime.parse("") == nil)
        #expect(DealTime.parse("not a time") == nil)
    }

    @Test func fromStringParsesFromPrefix() {
        #expect(DealTime.fromString("from 11AM") == .from(660))
        #expect(DealTime.fromString("FROM 11:30") == .from(690))
    }

    @Test func fromStringParsesTimeRange() {
        #expect(DealTime.fromString("4PM - 6PM") == .between(960, 1080))
        #expect(DealTime.fromString("4 PM - 6 PM") == .between(960, 1080))
    }

    @Test func fromStringReturnsNilForUnparseableInput() {
        #expect(DealTime.fromString("") == nil)
        #expect(DealTime.fromString("from") == nil)
        #expect(DealTime.fromString("not a time") == nil)
    }
}
