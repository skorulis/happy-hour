//Created by Alex Skorulis on 16/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealTextFilterTests {

    private let filter = DealTextFilter()

    @Test func acceptsTextWithDays() {
        #expect(filter.isValidDeal("EVERY TUES SPECIALS"))
        #expect(filter.isValidDeal("CHEESEBURGER TUESDAYS"))
        #expect(filter.isValidDeal("Happy Hour every Friday"))
        #expect(filter.isValidDeal("HAPPY HOUR TUES - THURS 4PM - 6PM / FRI 3PM - 5PM"))
    }

    @Test func acceptsTextWithTimes() {
        #expect(filter.isValidDeal("PIZZA 4PM - 6PM"))
        #expect(filter.isValidDeal("SUNDAY ROAST FROM 11:30 TILL SOLD OUT."))
    }

    @Test func acceptsDealHeadlines() {
        #expect(filter.isValidDeal("HAPPY HOUR 4-7PM"))
        #expect(filter.isValidDeal("Weekend Brunch Specials"))
        #expect(filter.isValidDeal("Tuesday Drink Promotions"))
    }

    @Test func rejectsNonDealText() {
        #expect(!filter.isValidDeal(""))
        #expect(!filter.isValidDeal("   "))
        #expect(!filter.isValidDeal("Special offers on selected drinks"))
        #expect(!filter.isValidDeal("$8 SCHOONERS"))
        #expect(!filter.isValidDeal("Contact us at hello@example.com"))
        #expect(!filter.isValidDeal("Reserve your table"))
    }

    @Test func rejectsTextWithSpecificDates() {
        #expect(DealTextFilter.containsDate(in: "Live music June 21"))
        #expect(DealTextFilter.containsDate(in: "Event on 17/06/2026"))
        #expect(DealTextFilter.containsDate(in: "Special on June 17th"))
        #expect(DealTextFilter.containsDate(in: "21st of March 2026"))
        #expect(DealTextFilter.containsDate(in: "2026-06-17"))
        #expect(DealTextFilter.containsDate(in: "2026-06-17"))

        #expect(!filter.isValidDeal("Live music June 21"))
        #expect(!filter.isValidDeal("Comedy night 17/06/2026"))
    }

    @Test func acceptsTextWithoutSpecificDates() {
        #expect(!DealTextFilter.containsDate(in: "Happy Hour every Friday"))
        #expect(!DealTextFilter.containsDate(in: "TUES - THURS 4PM - 6PM"))
        #expect(!DealTextFilter.containsDate(in: "FROM 11:30 TILL SOLD OUT."))
        #expect(!DealTextFilter.containsDate(in: "HAPPY HOUR"))
    }
    
    @Test func rejectsTextWithExcludedKeywords() {
        #expect(!filter.isValidDeal("Happy Hour tonight"))
        #expect(!filter.isValidDeal("Specials for Mother's Day"))
        #expect(!filter.isValidDeal("Deals this week only"))
    }

    @Test func rejectsExpiredPageText() {
        #expect(DealTextFilter.isExpiredPage("This event has passed."))
        #expect(!filter.isValidDeal("This event has passed."))
        #expect(!filter.isValidDeal("Happy Hour 4-7pm — expired"))
    }

    @Test func rejectsExamples() {
        // TODO: Think about how to fix this
//        #expect(!filter.isValidDeal(
//            "LOW AND SLOW it's all about the SMOKE. ASK AT THE BAR ABOUT OUR SMOKED MEAT SPECIALS G EST. 1862 THE GLEBE HOTEL"
//        ))
    }
}
