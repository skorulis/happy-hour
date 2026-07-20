//Created by Alex Skorulis on 20/7/2026.

import Foundation

nonisolated struct ProcessedDealPayload: Codable, Sendable {
    let deals: [ProcessedDeal]
}

nonisolated struct ProcessedDeal: Codable, Sendable {
    let title: String?
    let details: String?
    let conditions: String?
    let creativeURL: String?
    let sourceURL: String?
    let status: DealStatus
    let startDate: String?
    let endDate: String?
    let schedules: [ProcessedDealSchedule]

    init(
        title: String?,
        details: String?,
        conditions: String?,
        creativeURL: String?,
        sourceURL: String?,
        status: DealStatus,
        startDate: String?,
        endDate: String?,
        schedules: [ProcessedDealSchedule]
    ) {
        self.title = title
        self.details = details
        self.conditions = conditions
        self.creativeURL = creativeURL
        self.sourceURL = sourceURL
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.schedules = schedules
    }

    func toDealWithSchedules(venueId: Int64) -> DealWithSchedules {
        let deal = Deal(
            venueId: venueId,
            title: title,
            creativeURL: creativeURL,
            sourceURL: sourceURL,
            details: details,
            conditions: conditions,
            status: status,
            startDate: Self.parseDate(startDate),
            endDate: Self.parseDate(endDate)
        )
        let schedules = schedules.map {
            DealSchedule(
                dealId: 0,
                dayOfWeek: $0.dayOfWeek,
                startMinute: $0.startMinute,
                endMinute: $0.endMinute
            )
        }
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return dateFormatter.date(from: value)
    }
}

nonisolated struct ProcessedDealSchedule: Codable, Sendable {
    let dayOfWeek: Int
    let startMinute: Int
    let endMinute: Int
}
