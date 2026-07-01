//Created by Alex Skorulis on 22/6/2026.

import Foundation

enum JobType: String, Codable, Sendable {
    case crawlWebsite
    case extractDeals
    case crawlSuburb

    var displayLabel: String {
        switch self {
        case .crawlWebsite:
            return "Crawl Website"
        case .extractDeals:
            return "Extract Deals"
        case .crawlSuburb:
            return "Crawl Suburb"
        }
    }
}
