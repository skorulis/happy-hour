//Created by Alex Skorulis on 23/6/2026.

import Foundation

enum CrawlPolicy {

    private static let defaultMaxPages = 20
    
    private static let sharedSites: [String] = [
        "https://goodgoodcompany.com/",
        "https://hotelpalisade.com.au/",
        "https://holmanbarnesgroup.com.au/",
        "https://hunterstreethospitality.com.au/",
        "https://merivale.com/",
        "https://paisanoanddaughters.com.au/",
        "https://plateitforward.org.au/",
        "https://sundayco.com/",
        "https://sydneybrewery.com/",
        "https://thevenuesco.au/",
        "https://theharrysfamily.com.au/",
        "https://www.ihg.com/",
        "https://www.langhamhotels.com/",
        "https://www.liquidandlarder.com.au/",
        "https://www.lovetillygroup.com/",
        "https://www.muchogroup.com.au/",
        "https://www.oddculture.group/",
        "https://www.rydges.com/",
        "https://www.star.com.au/",
    ]
    
    private static let sharedSiteURLs: [URL] = sharedSites.map { URL(string: $0)! }
    
    private static func isSharedSite(_ url: URL) -> Bool {
        sharedSiteURLs.contains(where: { URLNormalizer.isSameOrigin($0, as: url) })
    }

    static func maxPages(for baseURL: URL) -> Int {
        if isSharedSite(baseURL) {
            return 1
        }
        return defaultMaxPages
    }

    static func shouldUseSitemap(for baseURL: URL) -> Bool {
        !isSharedSite(baseURL)
    }

    /// A lone discovered source is unambiguous enough to skip manual review.
    static func dealSourceStatus(discoveredCount: Int) -> DealStatus {
        discoveredCount == 1 ? .approved : .new
    }

    static func dealSourceStatus(for source: DiscoveredSource, discoveredCount: Int) -> DealStatus {
        if source.type == .image {
            let lines = textLines(from: source)
            if NthWeekdayOfMonthDetector.isMatch(in: lines)
                || SingleDateDetector.isMatch(in: lines) {
                return .rejected
            }
        }
        return dealSourceStatus(discoveredCount: discoveredCount)
    }

    private static func textLines(from source: DiscoveredSource) -> [String] {
        switch source.textPieces {
        case let .textLines(lines):
            return lines
        case let .contentBlocks(blocks):
            return blocks.map(\.text)
        case nil:
            return []
        }
    }
}
