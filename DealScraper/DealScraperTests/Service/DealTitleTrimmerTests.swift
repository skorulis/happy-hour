//Created by Alex Skorulis on 13/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTitleTrimmerTests {

    @Test func trimOnce_leavesBareTitleUntouched() {
        #expect(DealTitleTrimmer.trimOnce("Happy Hour") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("$8 Schooners") == "$8 Schooners")
    }

    @Test func trimOnce_trimsWhitespace() {
        #expect(DealTitleTrimmer.trimOnce("  Happy Hour  ") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("\nSteak Night\n") == "Steak Night")
    }

    @Test func trimOnce_returnsEmptyForWhitespaceOnlyInput() {
        #expect(DealTitleTrimmer.trimOnce("   ").isEmpty)
        #expect(DealTitleTrimmer.trimOnce("\n").isEmpty)
    }

    @Test func trimOnce_stripsCleanLineCharacters() {
        #expect(DealTitleTrimmer.trimOnce("*Happy Hour*") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("_Steak Night_") == "Steak Night")
        #expect(DealTitleTrimmer.trimOnce("|Pizza Night|") == "Pizza Night")
    }

    @Test func trimOnce_stripsLeadingDayWord() {
        #expect(DealTitleTrimmer.trimOnce("TUESDAY Steak Night") == "Steak Night")
        #expect(DealTitleTrimmer.trimOnce("Friday Happy Hour") == "Happy Hour")
    }

    @Test func trimOnce_stripsTrailingDayWord() {
        #expect(DealTitleTrimmer.trimOnce("Night Trivia Tuesday") == "Night Trivia")
        #expect(DealTitleTrimmer.trimOnce("Steak Night Thurs") == "Steak Night")
    }

    @Test func trimOnce_keepsPluralDayWordsInTitle() {
        #expect(DealTitleTrimmer.trimOnce("Cheeseburger Tuesdays") == "Cheeseburger Tuesdays")
    }

    @Test func trimOnce_stripsSingleDayOnlyTitle() {
        #expect(DealTitleTrimmer.trimOnce("Tuesday").isEmpty)
    }

    @Test func trimOnce_stripsAvailableFromSuffix() {
        #expect(DealTitleTrimmer.trimOnce("Lunch Available From 12PM") == "Lunch")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour available from 5pm") == "Happy Hour")
    }

    @Test func trimOnce_stripsFullTimeRangeSuffix() {
        #expect(DealTitleTrimmer.trimOnce("$19 Chicken Parmi 4PM - 6PM") == "$19 Chicken Parmi")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM to 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM til 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM till 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM 'til 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM until 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM – 6PM") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM — 6PM") == "Happy Hour")
    }

    @Test func trimOnce_stripsPartialTimeRangeSuffix() {
        #expect(DealTitleTrimmer.trimOnce("$19 Chicken Parmi 4PM -") == "$19 Chicken Parmi")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM –") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 4PM —") == "Happy Hour")
    }

    @Test func trimOnce_stripsTrailingTime() {
        #expect(DealTitleTrimmer.trimOnce("Lunch From 12PM") == "Lunch")
        #expect(DealTitleTrimmer.trimOnce("Night Trivia 6:30PM") == "Night Trivia")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 430pm") == "Happy Hour")
    }

    @Test func trimOnce_stripsTrailingFromWordAfterTimeRemoved() {
        #expect(DealTitleTrimmer.trimOnce("Bottle Shop Wines From $20") == "Bottle Shop Wines From $20")
        #expect(DealTitleTrimmer.trimOnce("Lunch From") == "Lunch")
    }

    @Test func trimOnce_stripsTrailingOrphanSeparator() {
        #expect(DealTitleTrimmer.trimOnce("Happy Hour -") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour –") == "Happy Hour")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour —") == "Happy Hour")
    }

    @Test func trimOnce_doesNotStripInvalidTrailingTimes() {
        #expect(DealTitleTrimmer.trimOnce("Happy Hour 25:00") == "Happy Hour 25:00")
        #expect(DealTitleTrimmer.trimOnce("Happy Hour not a time") == "Happy Hour not a time")
    }

    @Test func trimOnce_mayNeedAnotherPassWhenDayFollowsRemovedTime() {
        #expect(DealTitleTrimmer.trimOnce("Night Trivia Tuesday 6:30PM") == "Night Trivia Tuesday")
        #expect(DealTitleTrimmer.trimUntilStable("Night Trivia Tuesday 6:30PM") == "Night Trivia")
    }

    @Test func trimOnce_isIdempotentAfterStable() {
        let samples = [
            "Happy Hour",
            "Steak Night",
            "Night Trivia",
            "$19 Chicken Parmi",
            "Cheeseburger Tuesdays",
        ]

        for sample in samples {
            #expect(DealTitleTrimmer.trimOnce(sample) == sample)
        }
    }

    @Test func trimUntilStable_stripsDayAndTimeTogether() {
        #expect(DealTitleTrimmer.trimUntilStable("NIGHT TRIVIA TUESDAY 6:30PM") == "NIGHT TRIVIA")
    }

    @Test func trimUntilStable_matchesTrimOnceForRepresentativeTitles() {
        let samples = [
            "Happy Hour 4PM - 6PM",
            "TUESDAY HAPPY HOUR 4PM - 6PM",
            "Lunch Available From 12PM",
            "$19 CHICKEN PARMI 4PM -",
        ]

        for sample in samples {
            #expect(DealTitleTrimmer.trimUntilStable(sample) == DealTitleTrimmer.trimOnce(sample))
        }
    }

    @Test func trimUntilStable_isStable() {
        let samples = [
            "Happy Hour",
            "NIGHT TRIVIA TUESDAY 6:30PM",
            "FRIDAY LUNCH FROM 12PM",
        ]

        for sample in samples {
            let trimmed = DealTitleTrimmer.trimUntilStable(sample)
            #expect(DealTitleTrimmer.trimUntilStable(trimmed) == trimmed)
        }
    }
}
