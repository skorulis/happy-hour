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
        #expect(DealHours.toMinutes(string: "6.30pm") == 1110)
        #expect(DealHours.toMinutes(string: "4.30 PM") == 990)
        #expect(DealHours.toMinutes(string: "630pm") == 18 * 60 + 30)
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

    @Test func parsesNamedTimes() {
        #expect(DealHours.toMinutes(string: "NOON") == 12 * 60)
        #expect(DealHours.toMinutes(string: "midnight") == 0)
    }

    @Test func parseNoonTimeRange() {
        #expect(DealHours.parse("NOON - 4PM") == .between(12 * 60, 16 * 60))
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
        #expect(DealHours.parse("5pm-630pm") == .between(17 * 60, 18 * 60 + 30))
    }

    @Test func parseAllDay() {
        #expect(DealHours.parse("all day") == .allDay)
        #expect(DealHours.parse("ALL DAY") == .allDay)
        #expect(DealHours.parse("all-day") == .allDay)
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
        #expect(DealHours.fromString("FROM 4-6PM") == .between(960, 1080))
    }

    @Test func parseFromPrefixedCompactTimeRange() {
        #expect(DealHours.parse("FROM 4-6PM") == .between(960, 1080))
        #expect(DealHours.parse("from 4-6pm") == .between(960, 1080))
    }

    @Test func fromStringReturnsNilForUnparseableInput() {
        #expect(DealHours.fromString("") == nil)
        #expect(DealHours.fromString("from") == nil)
        #expect(DealHours.fromString("not a time") == nil)
    }

    @Test func parseOvernightTimeRangeBeforeTenAM() {
        #expect(DealHours.parse("10PM - 2AM") == .between(22 * 60, 26 * 60))
        #expect(DealHours.parse("4pm-2am") == .between(16 * 60, 26 * 60))
    }

    @Test func parseMidnightEndOfDayIsNotTreatedAsOvernight() {
        #expect(DealHours.parse("10PM - midnight") == .between(22 * 60, 24 * 60))
    }

    @Test func parseSameDayMorningRangeIsNotTreatedAsOvernight() {
        #expect(DealHours.parse("1AM - 2AM") == .between(60, 120))
    }

    @Test func adjustedEndMinuteExtendsEarlyMorningEndIntoNextDay() {
        #expect(DealHours.adjustedEndMinute(start: 22 * 60, end: 2 * 60) == 26 * 60)
        #expect(DealHours.adjustedEndMinute(start: 16 * 60, end: 18 * 60) == 18 * 60)
    }
}
