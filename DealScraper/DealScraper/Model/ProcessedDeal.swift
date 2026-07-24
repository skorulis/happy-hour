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
    let products: [ExtractedProductPayload]

    init(
        title: String?,
        details: String?,
        conditions: String?,
        creativeURL: String?,
        sourceURL: String?,
        status: DealStatus,
        startDate: String?,
        endDate: String?,
        schedules: [ProcessedDealSchedule],
        products: [ExtractedProductPayload] = []
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
        self.products = products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        conditions = try container.decodeIfPresent(String.self, forKey: .conditions)
        creativeURL = try container.decodeIfPresent(String.self, forKey: .creativeURL)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        status = try container.decode(DealStatus.self, forKey: .status)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        schedules = try container.decode([ProcessedDealSchedule].self, forKey: .schedules)
        products = try container.decodeIfPresent([ExtractedProductPayload].self, forKey: .products) ?? []
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
        let products = products.map {
            DealProduct(
                dealId: 0,
                product: $0.name,
                price: $0.price
            )
        }
        return DealWithSchedules(deal: deal, schedules: schedules, products: products)
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
