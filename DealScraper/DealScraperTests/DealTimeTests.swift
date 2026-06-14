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
}
