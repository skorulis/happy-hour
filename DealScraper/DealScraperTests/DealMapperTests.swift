//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealMapperTests {

    @Test func mapsRawDealWithDaysAndTimes() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "CHEESEBURGER TUESDAYS",
            details: ["TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS"],
            days: ["EVERY TUES"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])

        #expect(deals.count == 1)
        let deal = try #require(deals.first)
        #expect(deal.title == "Cheeseburger Tuesdays")
        #expect(deal.details == ["Ten dollar beef or vegan cheeseburgers with chips"])
        #expect(deal.days == [.tuesday])
        #expect(deal.times == [.allDay])
    }

    @Test func parsesTimeRangeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["TUES - THURS"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.days == [.tuesday, .wednesday, .thursday])
        #expect(deal.times.contains(.between(16 * 60, 18 * 60)))
    }

    @Test func expandsMondayToFridayDayRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["MONDAY - FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
    }

    @Test func expandsMondayThroughWednesdayDayRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["Monday through Wednesday"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.days == [.monday, .tuesday, .wednesday])
    }

    @Test func supplementsMissingTimesFromContext() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: []
        )

        let deals = DealMapper.map([raw], supplementFrom: ["TUES - THURS 4PM - 6PM / FRI 3PM - 5PM"])
        let deal = try #require(deals.first)

        #expect(!deal.times.isEmpty)
    }

    @Test func mergesDealsWithSharedText() {
        let first = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 WINES"],
            days: ["TUESDAY"],
            times: ["4PM - 6PM"]
        )
        let second = DealExtractionPayload.RawDeal(
            title: "",
            details: ["$8 WINES"],
            days: ["THURSDAY"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([first, second])

        #expect(deals.count == 1)
        #expect(deals.first?.days.contains(.tuesday) == true)
        #expect(deals.first?.days.contains(.thursday) == true)
    }

    @Test func parsesTillTimeAsUntilEndOfRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "LATE NIGHT SPECIAL",
            details: ["$5 BEERS"],
            days: ["FRIDAY"],
            times: ["till 10pm"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(0, 22 * 60)])
    }

    @Test func parsesFromTillTimeRange() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 WINES"],
            days: ["FRIDAY"],
            times: ["from 4pm till 10pm"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(16 * 60, 22 * 60)])
    }

    @Test func parsesPmTillPmTimeRangeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 WINES"],
            days: ["FRIDAY"],
            times: ["4pm \u{2019}til 6pm"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesBareHourTillPmTimeRangeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "LUNCH SPECIAL",
            details: ["$15 MAINS"],
            days: ["SATURDAY"],
            times: ["12 \u{2019}TIL 3PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.times == [.between(12 * 60, 15 * 60)])
    }

    @Test func parsesCompactTimeRangeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["5pm-630pm"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.times == [.between(17 * 60, 18 * 60 + 30)])
    }

    @Test func parsesDotSeparatedTimeFromRawDeal() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["6.30pm"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.times == [.from(18 * 60 + 30)])
    }

    @Test func stripsLeadingAsteriskFromConditions() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22 STEAK"],
            conditions: ["*only available with bar service"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])
        let deal = try #require(deals.first)

        #expect(deal.conditions == ["only available with bar service"])
    }

    @Test func filtersEmptyRawDeals() {
        let raw = DealExtractionPayload.RawDeal(
            title: "   ",
            details: [],
            days: [],
            times: []
        )

        let deals = DealMapper.map([raw])

        #expect(deals.isEmpty)
    }

    @Test func removesTitleRepeatedInDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["HAPPY HOUR", "$8 WINES"],
            days: ["FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Happy Hour")
        #expect(deal.details == ["$8 Wines"])
    }

    @Test func removesDuplicateDetailLines() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "TACO TUESDAY",
            details: ["$2 TACOS", "$2 TACOS", "$3 BEERS"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["$2 Tacos", "$3 Beers"])
    }

    @Test func deduplicatesDetailsCaseInsensitively() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "WING WEDNESDAY",
            details: ["$1 WINGS", "$1 wings"],
            days: ["WEDNESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["$1 Wings"])
    }

    @Test func removesConditionsDuplicatingTitleOrDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22 STEAK"],
            conditions: ["STEAK NIGHT", "$22 STEAK", "dine-in only"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.conditions == ["dine-in only"])
    }

    @Test func appendsLeadingPriceDetailToTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["$22", "Premium cut with sides"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Steak Night $22")
        #expect(deal.details == ["Premium cut with sides"])
    }

    @Test func usesLeadingPriceAsTitleWhenTitleIsEmpty() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "",
            details: ["$39PP", "Sunday roast with all the trimmings"],
            days: ["SUNDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$39PP")
        #expect(deal.details == ["Sunday roast with all the trimmings"])
    }

    @Test func doesNotAppendPricePlusDescriptionDetailToTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Happy Hour")
        #expect(deal.details == ["$8 Schooners"])
    }

    @Test func doesNotDuplicateLeadingPriceAlreadyInTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "$22 STEAK NIGHT",
            details: ["$22", "Raise the Steaks"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$22 Steak Night")
        #expect(deal.details == ["Raise the steaks"])
    }

    @Test func stripsDayFromStartOfTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "MONDAY STEAK NIGHT",
            details: ["Raise the steaks"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Steak Night")
        #expect(deal.details == ["Raise the steaks"])
    }

    @Test func stripsDayFromEndOfTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT TUESDAY",
            details: ["Raise the steaks"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Steak Night")
        #expect(deal.details == ["Raise the steaks"])
    }

    @Test func appendsFirstDetailLineWhenTitleIsPriceOnly() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "$22",
            details: ["Premium cut with sides", "Selected cuts only"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$22 Premium Cut With Sides")
        #expect(deal.details == ["Selected cuts only"])
    }

    @Test func replacesDayOnlyTitleWithFirstDetailLine() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "Monday",
            details: ["$5 BEERS", "Selected tap beers only"],
            days: ["MONDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$5 Beers")
        #expect(deal.details == ["Selected tap beers only"])
    }

    @Test func replacesDayOnlyTitleWithFirstLineOfMultilineDetail() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "TUESDAY",
            details: ["STEAK NIGHT\n$22 PREMIUM CUT"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Steak Night")
        #expect(deal.details == ["$22 Premium cut"])
    }

    @Test func rejectsDayOnlyTitleWhenDetailsAreEmpty() {
        let raw = DealExtractionPayload.RawDeal(
            title: "Wednesday",
            details: [],
            conditions: ["Bar service only"],
            days: ["WEDNESDAY"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])

        #expect(deals.isEmpty)
    }

    @Test func keepsNonDayOnlyTitlesUnchanged() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "CHEESEBURGER TUESDAYS",
            details: ["TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS"],
            days: ["TUESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Cheeseburger Tuesdays")
    }

    @Test func filtersDealsWithExcludedKeywordsInTitle() {
        let footy = DealExtractionPayload.RawDeal(
            title: "LIVE & LOUD FOOTY",
            details: ["Hahn super dry pints for schooner prices whenever the games on."],
            days: ["FRIDAY"],
            times: ["all day"]
        )
        let origin = DealExtractionPayload.RawDeal(
            title: "WELCOME TO ORIGIN 2026",
            details: ["Catch the action live, loud and with $9 pints of tooheys new."],
            days: ["WEDNESDAY"],
            times: ["all day"]
        )
        let happyHour = DealExtractionPayload.RawDeal(
            title: "HAPPY HOUR",
            details: ["$7.50 schooners & $10 pints of select house beers"],
            days: ["MONDAY - FRIDAY"],
            times: ["4PM - 6PM"]
        )

        let deals = DealMapper.map([footy, origin, happyHour])

        #expect(deals.count == 1)
        #expect(deals.first?.title == "Happy Hour")
    }

    @Test func filtersExcludedKeywordsInResolvedDayOnlyTitle() {
        let raw = DealExtractionPayload.RawDeal(
            title: "FRIDAY",
            details: ["LIVE & LOUD FOOTY", "Pints for schooner prices"],
            days: ["FRIDAY"],
            times: ["all day"]
        )

        let deals = DealMapper.map([raw])

        #expect(deals.isEmpty)
    }

    @Test func sentenceCasesMultilineDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "STEAK NIGHT",
            details: ["RAISE THE STEAKS\nWITH ALL THE TRIMMINGS\n$22 EACH"],
            days: ["MONDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["Raise the steaks\nWith all the trimmings\n$22 Each"])
    }

    @Test func parsesParenthesizedTimeRangeFromRawDeal() throws {
        let json = """
        {"deals":[{"days":["TUE - FRI"],"times":["(11 AM - 2 PM )"],"conditions":[],"title":"$25\\nPIZZA!\\n+BEER","details":[]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let raw = try #require(payload.deals.first)

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$25 Pizza! +Beer")
        #expect(deal.days == [.tuesday, .wednesday, .thursday, .friday])
        #expect(deal.times == [.between(11 * 60, 14 * 60)])
    }

    @Test func parsesNoonTimeRangeFromRawDeal() throws {
        let json = """
        {"deals":[{"title":"Sunday ROOFTOP PARMA","conditions":["AVAILABLE ON THE ROOFTOP TERRACE & FIRST FLOOR, WITH A DRINK PURCHASE*","Qualifying drinks: Bottle of beer or RTD. Pint of beer or soft drink. Glass of wine or cocktail","Specials & Promos are not available for functions\\/events or on Public Holidays\\/Special Event Days.","Promos subject to change without notice."],"days":["SUNDAYS"],"times":["NOON - 4PM"],"details":["$7.5","Chicken Parma","SERVED WITH CHIPS"]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let raw = try #require(payload.deals.first)

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Rooftop Parma $7.5")
        #expect(deal.days == [.sunday])
        #expect(deal.times == [.between(12 * 60, 16 * 60)])
    }

    @Test func stripsTrailingTimeFromTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "NIGHT TRIVIA 6:30PM",
            details: [],
            days: ["TUESDAY"],
            times: ["6:30PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Night Trivia")
    }

    @Test func stripsAvailableFromTimeSuffixFromTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "BOTTLE SHOP WINES FROM $20 AVAILABLE FROM 5PM",
            details: [],
            days: ["FRIDAY"],
            times: ["5PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Bottle Shop Wines From $20")
    }

    @Test func stripsTrailingFromAfterTimeRemovedFromTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "LUNCH FROM 12PM",
            details: [],
            days: ["WEEKDAY"],
            times: ["12PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Lunch")
    }

    @Test func stripsTrailingTimeRangeFromTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "$19 CHICKEN PARMI 4PM - 6PM",
            details: [],
            days: ["MONDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$19 Chicken Parmi")
    }

    @Test func stripsDanglingTimeRangeSeparatorFromTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "$19 CHICKEN PARMI 4PM -",
            details: [],
            days: ["MONDAY"],
            times: ["4PM - 6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "$19 Chicken Parmi")
    }

    @Test func stripsDayAfterTrailingTimeRemoved() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "NIGHT TRIVIA TUESDAY 6:30PM",
            details: [],
            days: ["TUESDAY"],
            times: ["6:30PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Night Trivia")
    }

    @Test func mountbattenHappyHourAndCocktailsShouldStaySeparateWhenMappedTogether() throws {
        let happyHourJSON = """
        {"deals":[{"title":"Happy Hour","details":["LET'S DRINK TO THAT!"],"days":["EVERY DAY"],"times":["5PM - 8PM"],"conditions":["Conditions apply.","Available to LDA Rewards members only.","Selected beers and wines only.","This promotion is at management's discretion and may not be available on public holidays or some special events.","Mountbatten Hotel practices the Responsible Service of Alcohol.","Please drink responsibly."]}]}
        """
        let cocktailsJSON = """
        {"deals":[{"title":"$14 Cocktails","details":["A TASTE OF PERFECTION"],"days":["EVERY DAY"],"times":["5PM - 8PM"],"conditions":["Conditions apply.","Available to JDA Rewards members only.","This promotion is at management's discretion and may not be available on public holidays or some special events.","Please drink responsibly."]}]}
        """
        let happyHourPayload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(happyHourJSON.utf8))
        let cocktailsPayload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(cocktailsJSON.utf8))
        let happyHour = try #require(happyHourPayload.deals.first)
        let cocktails = try #require(cocktailsPayload.deals.first)

        let deals = DealMapper.map([happyHour, cocktails])

        // DealMapper.merge treats matching times as sufficient to merge, even when
        // titles and products differ. That drops one of the two Mountbatten deals.
        #expect(deals.count == 2)
        #expect(deals.contains { $0.title == "Happy Hour" })
        #expect(deals.contains { $0.title == "$14 Cocktails" })
    }

    @Test func parsesStartBetweenTimeRangeFromRawDeal() throws {
        let json = """
        {"deals":[{"times":["with a start between 12pm-3:15pm."],"days":["Friday\\/Saturday\\/Sunday"],"title":"BOTTOMLESS DAIQUIRI LUNCH","conditions":["Please note - there is a 5% surcharge on Sundays, 7.5% service fee on groups of 8+ and a 12.5% surcharge on public holidays"],"details":["Get Tropical every weekend at Rosie Campbells.","Our Bottomless Lunch is perfect for your mini getaway for a celebration or catch up with friends!","DJ Kimani on the decks every Saturday.","Get the group together and enjoy 90 minutes of free flowing Daiquiri's & Pina Colada's, served with a 5 course island banquet for $99pp. Available, Friday\\/Saturday\\/Sunday with a start between 12pm-3:15pm.","90 Minute Drink & food package","- Unlimited Daiquiri's (3 Flavours available) & Pina Colada's","- Sparkling Wine & Tap Beer","- **Plantain Fritters** – Plantains, corn & jalapeno fritters with mango salsa","- **Island Taco** – Choice of jerk chicken or veggie","- **Kingston Prawns** – Coconut Chilli & coriander prawns with coconut pita bread","- **Famous Jerk Chicken** – Flame grilled jerk marinated chicken thigh, pineapple salsa & jerk sauce","- **Rice N Peas -** coconut jasmine rice, turtle peas, thyme, shallots"]},{"times":["all day"],"days":["TUESDAY"],"title":"TUESDAY | $1 JERK WINGS","conditions":[],"details":[]},{"times":["all day"],"days":["WEDNESDAY"],"title":"WEDNESDAY | SEAFOOD BOIL","conditions":[],"details":[]},{"times":["all day"],"days":["SUNDAY"],"title":"SUNDAY | SOUL FOOD PLATTER","conditions":[],"details":[]},{"times":["4-6PM"],"days":["WEEKDAYS"],"title":"WEEKDAYS 4-6PM | HAPPY HOUR","conditions":[],"details":[]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let deals = DealMapper.map(payload.deals)

        #expect(deals.count == 5)

        let bottomless = try #require(deals.first { $0.title == "Bottomless Daiquiri Lunch" })
        #expect(bottomless.days == [.friday, .saturday, .sunday])
        #expect(bottomless.times == [.between(12 * 60, 15 * 60 + 15)])

        let jerkWings = try #require(deals.first { $0.title == "$1 Jerk Wings" })
        #expect(jerkWings.days == [.tuesday])
        #expect(jerkWings.times == [.allDay])

        let seafoodBoil = try #require(deals.first { $0.title == "Seafood Boil" })
        #expect(seafoodBoil.days == [.wednesday])
        #expect(seafoodBoil.times == [.allDay])

        let soulFood = try #require(deals.first { $0.title == "Soul Food Platter" })
        #expect(soulFood.days == [.sunday])
        #expect(soulFood.times == [.allDay])

        let happyHour = try #require(deals.first { $0.title == "Weekdays 4-6pm | Happy Hour" })
        #expect(happyHour.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(happyHour.times == [.between(16 * 60, 18 * 60)])
    }

    @Test func parsesMarkdownBoldWrappedTimesFromRawDeal() throws {
        let json = """
        {"deals":[{"details":["Enjoy $4 wings, $8 select beers, and $11 Boozy Juice while the vibes roll on."],"title":"**Butter Happy Hour**","days":["weekdays"],"times":["**3PM–6PM**"],"conditions":[]},{"details":["Grab a **$20 sando + fries**, **$5 donuts**, and **$15 selected cocktails** to keep the party going."],"title":"**Late Night Feast**","days":["daily"],"times":["**9PM till close**"],"conditions":[]}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let deals = DealMapper.map(payload.deals)

        #expect(deals.count == 2)

        let happyHour = try #require(deals.first { $0.title == "Butter Happy Hour" })
        #expect(happyHour.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(happyHour.times == [.between(15 * 60, 18 * 60)])

        let lateNight = try #require(deals.first { $0.title == "Late Night Feast" })
        #expect(lateNight.times == [.from(21 * 60)])
    }

    @Test func mapsHappyHourWithSplitEveryWeekdayDays() throws {
        let json = """
        {"deals":[{"conditions":["* SELECTED RANGE OF BEER & WINE"],"times":["4PM-6PM"],"details":["BEERS","$7-"],"days":["EVERY","WEEKDAY"],"title":"HAPPY HOUR"}]}
        """
        let payload = try JSONDecoder().decode(DealExtractionPayload.self, from: Data(json.utf8))
        let raw = try #require(payload.deals.first)

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Happy Hour")
        #expect(deal.details == ["Beers", "$7-"])
        #expect(deal.conditions == ["SELECTED RANGE OF BEER & WINE"])
        #expect(deal.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(deal.times == [.between(16 * 60, 18 * 60)])
    }

    @Test func lowercasesMeasurementUnitsAfterNumbersInTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "1KG WINGSDAY",
            details: ["All-you-can-eat wings"],
            days: ["WEDNESDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "1kg Wingsday")
    }

    @Test func lowercasesMeasurementUnitsWithSpaceAfterNumbersInTitle() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "500 ML PINT SPECIAL",
            details: [],
            days: ["FRIDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "500ml Pint Special")
    }

    @Test func lowercasesAmPmAfterNumbersInDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "Happy Hour",
            details: ["Drinks special from 4PM until 6PM"],
            days: ["WEEKDAYS"],
            times: ["4PM-6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.details == ["Drinks special from 4pm until 6pm"])
    }

    @Test func lowercasesAmPmLeftInTitleWhenNotTrimmed() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "WEEKDAYS 4-6PM | HAPPY HOUR",
            details: [],
            days: ["WEEKDAYS"],
            times: ["4-6PM"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Weekdays 4-6pm | Happy Hour")
    }

    @Test func lowercasesPpAfterNumbersInTitleAndDetails() throws {
        let raw = DealExtractionPayload.RawDeal(
            title: "BOTTOMLESS LUNCH $99PP",
            details: ["Island banquet for $99PP per person"],
            days: ["FRIDAY"],
            times: ["all day"]
        )

        let deal = try #require(DealMapper.map([raw]).first)

        #expect(deal.title == "Bottomless Lunch $99pp")
        #expect(deal.details == ["Island banquet for $99pp per person"])
    }
}
