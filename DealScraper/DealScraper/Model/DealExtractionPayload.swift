//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct DealExtractionPayload: Codable, Sendable {
    struct RawDeal: Codable, Sendable {
        let title: String
        let details: [String]
        let conditions: [String]
        let days: [String]
        let times: [String]

        init(
            title: String,
            details: [String],
            conditions: [String] = [],
            days: [String],
            times: [String]
        ) {
            self.title = title
            self.details = details
            self.conditions = conditions
            self.days = days
            self.times = times
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decode(String.self, forKey: .title)
            details = try container.decode([String].self, forKey: .details)
            conditions = try container.decodeIfPresent([String].self, forKey: .conditions) ?? []
            days = try container.decode([String].self, forKey: .days)
            times = try container.decode([String].self, forKey: .times)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(details, forKey: .details)
            try container.encode(conditions, forKey: .conditions)
            try container.encode(days, forKey: .days)
            try container.encode(times, forKey: .times)
        }

        private enum CodingKeys: String, CodingKey {
            case title
            case details
            case conditions
            case days
            case times
        }
    }

    let deals: [RawDeal]
}

nonisolated struct SourcedDealExtraction: Sendable {
    let material: VenueDealSourceMaterial
    let deals: [DealExtractionPayload.RawDeal]
}
