//Created by Alex Skorulis on 23/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealScheduleFormattingTests {

    @Test func condensesConsecutiveDaysWithSameTime() {
        let schedules = [
            schedule(day: 2, start: 16 * 60, end: 18 * 60),
            schedule(day: 3, start: 16 * 60, end: 18 * 60),
        ]

        #expect(DealScheduleFormatting.formattedSummary(schedules) == "Mon-Tue 16:00–18:00")
    }

    @Test func keepsNonConsecutiveDaysSeparateWithinSameTime() {
        let schedules = [
            schedule(day: 2, start: 16 * 60, end: 18 * 60),
            schedule(day: 4, start: 16 * 60, end: 18 * 60),
        ]

        #expect(DealScheduleFormatting.formattedSummary(schedules) == "Mon, Wed 16:00–18:00")
    }

    @Test func condensesLongWeekdayRun() {
        let schedules = (2...6).map { schedule(day: $0, start: 16 * 60, end: 18 * 60) }

        #expect(DealScheduleFormatting.formattedSummary(schedules) == "Mon-Fri 16:00–18:00")
    }

    @Test func condensesWeekendDaysAcrossSunday() {
        let schedules = [
            schedule(day: 6, start: 16 * 60, end: 18 * 60),
            schedule(day: 7, start: 16 * 60, end: 18 * 60),
            schedule(day: 1, start: 16 * 60, end: 18 * 60),
        ]

        #expect(DealScheduleFormatting.formattedSummary(schedules) == "Fri-Sun 16:00–18:00")
    }

    @Test func omitsTimeForAllDaySchedules() {
        let schedules = [
            schedule(day: 2, start: 0, end: 1_440),
            schedule(day: 3, start: 0, end: 1_440),
        ]

        #expect(DealScheduleFormatting.formattedSummary(schedules) == "Mon-Tue")
    }

    @Test func formatsMultipleTimeRanges() {
        let schedules = [
            schedule(day: 2, start: 16 * 60, end: 18 * 60),
            schedule(day: 3, start: 16 * 60, end: 18 * 60),
            schedule(day: 5, start: 12 * 60, end: 14 * 60),
        ]

        #expect(
            DealScheduleFormatting.formattedSummary(schedules)
                == "Mon-Tue 16:00–18:00, Thu 12:00–14:00"
        )
    }

    @Test func dealWithSchedulesUsesFormattedSummary() {
        let item = DealWithSchedules(
            deal: Deal(
                id: 1,
                venueId: 1,
                title: "Happy hour",
                imageURL: nil,
                sourceURL: nil,
                details: nil,
                conditions: nil,
                status: .approved
            ),
            schedules: [
                schedule(day: 2, start: 16 * 60, end: 18 * 60),
                schedule(day: 3, start: 16 * 60, end: 18 * 60),
            ]
        )

        #expect(item.formattedScheduleSummary == "Mon-Tue 16:00–18:00")
    }

    private func schedule(day: Int, start: Int, end: Int) -> DealSchedule {
        DealSchedule(dealId: 1, dayOfWeek: day, startMinute: start, endMinute: end)
    }
}
