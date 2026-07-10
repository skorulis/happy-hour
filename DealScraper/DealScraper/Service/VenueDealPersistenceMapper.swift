//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealPersistenceMapper {

    nonisolated static func map(
        sourced: [SourcedDealExtraction],
        venueId: Int64
    ) -> [DealWithSchedules] {
        sourced.flatMap { extraction in
            map(
                payload: DealExtractionPayload(deals: extraction.deals),
                venueId: venueId,
                material: extraction.material
            )
        }
    }

    nonisolated static func map(
        payload: DealExtractionPayload,
        venueId: Int64,
        material: VenueDealSourceMaterial
    ) -> [DealWithSchedules] {
        payload.deals.compactMap { raw in
            map(rawDeal: raw, venueId: venueId, material: material)
        }
    }

    nonisolated private static func map(
        rawDeal: DealExtractionPayload.RawDeal,
        venueId: Int64,
        material: VenueDealSourceMaterial
    ) -> DealWithSchedules? {
        guard let legacyDeal = DealMapper.map(rawDeal) else { return nil }

        let creativeURL: String? = switch material.type {
        case .image, .pdf:
            material.url.absoluteString
        case .webpage:
            nil
        }
        let sourceURL = material.sourceURL.absoluteString

        let details = joinedNonEmpty(legacyDeal.details)
        let conditions = joinedNonEmpty(legacyDeal.conditions)
        let title = legacyDeal.title

        guard !title.isEmpty || details != nil || conditions != nil else { return nil }

        let promotionDates = PromotionDateParser.parse(rawDeal.promotionDates)

        let autoReject =
            NthWeekdayOfMonthDetector.isMatch(
                title: rawDeal.title,
                details: rawDeal.details + legacyDeal.details,
                conditions: rawDeal.conditions + legacyDeal.conditions,
                days: rawDeal.days
            )
            || hasSameDayPromotionDates(
                start: promotionDates.start,
                end: promotionDates.end
            )

        let deal = Deal(
            venueId: venueId,
            title: title.isEmpty ? nil : title,
            creativeURL: creativeURL,
            sourceURL: sourceURL,
            details: details,
            conditions: conditions,
            status: autoReject ? .rejected : .new,
            startDate: promotionDates.start,
            endDate: promotionDates.end
        )

        let schedules = schedules(for: legacyDeal, title: title, details: details)
        guard !schedules.isEmpty || deal.startDate != nil || deal.endDate != nil else {
            return nil
        }
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    nonisolated private static func hasSameDayPromotionDates(start: Date?, end: Date?) -> Bool {
        guard let start, let end else { return false }
        return Calendar.current.isDate(start, inSameDayAs: end)
    }

    nonisolated private static func joinedNonEmpty(_ strings: [String]) -> String? {
        let joined = strings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return joined.isEmpty ? nil : joined
    }

    nonisolated private static func schedules(
        for legacyDeal: LegacyDeal,
        title: String,
        details: String?
    ) -> [DealSchedule] {
        let days = legacyDeal.days.flatMap(\.scheduleDays)
        let times = legacyDeal.times.isEmpty ? [DealHours.allDay] : legacyDeal.times
        guard !days.isEmpty else { return [] }

        let adjustDinnerStart = shouldAdjustDinnerStart(title: title, details: details)

        var schedules: [DealSchedule] = []
        for day in days {
            for time in times {
                let range = scheduleRange(for: time, adjustDinnerStart: adjustDinnerStart)
                schedules.append(
                    DealSchedule(
                        dealId: 0,
                        dayOfWeek: day.calendarWeekday,
                        startMinute: range.start,
                        endMinute: range.end
                    )
                )
            }
        }
        return schedules
    }

    nonisolated private static func shouldAdjustDinnerStart(title: String, details: String?) -> Bool {
        var combined = title
        if let details, !details.isEmpty {
            combined = combined.isEmpty ? details : "\(combined) \(details)"
        }
        let lowercased = combined.lowercased()
        return lowercased.contains("dinner") && !lowercased.contains("lunch")
    }

    nonisolated private static func scheduleRange(
        for hours: DealHours,
        adjustDinnerStart: Bool
    ) -> (start: Int, end: Int) {
        var range: (start: Int, end: Int)
        switch hours {
        case .allDay:
            range = (0, 1_440)
        case let .from(minutes):
            range = (minutes, 1_440)
        case let .between(start, end):
            range = (start, end)
        }

        if adjustDinnerStart, range.start == 0 {
            range.start = 17 * 60
        }
        return range
    }
}
