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
            details = try Self.decodeStringOrArray(from: container, forKey: .details)
            conditions = try Self.decodeStringOrArrayIfPresent(from: container, forKey: .conditions)
            days = try Self.decodeStringOrArray(from: container, forKey: .days)
            times = try Self.decodeStringOrArray(from: container, forKey: .times)
        }

        private static func decodeStringOrArray(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> [String] {
            if let array = try? container.decode([String].self, forKey: key) {
                return array
            }
            if let string = try? container.decode(String.self, forKey: key) {
                return [string]
            }
            throw DecodingError.typeMismatch(
                [String].self,
                DecodingError.Context(codingPath: container.codingPath + [key], debugDescription: "Expected string or array of strings")
            )
        }

        private static func decodeStringOrArrayIfPresent(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> [String] {
            guard container.contains(key) else { return [] }
            return try decodeStringOrArray(from: container, forKey: key)
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
