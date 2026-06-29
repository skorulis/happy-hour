//Created by Alex Skorulis on 23/6/2026.

import Foundation

enum CrawlPolicy {

    private static let defaultMaxPages = 20
    
    private static let sharedSites: [String] = [
        "https://merivale.com/",
        "https://hotelpalisade.com.au/",
        "https://sydneybrewery.com/",
        "https://www.oddculture.group/",
        "https://www.muchogroup.com.au/",
        "https://www.liquidandlarder.com.au/",
        "https://paisanoanddaughters.com.au/"
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
}
