//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct DealExtractionPayload: Codable, Sendable {
    struct RawDeal: Codable, Sendable {
        let title: String
        let details: [String]
        let days: [String]
        let times: [String]
    }

    let deals: [RawDeal]
}
