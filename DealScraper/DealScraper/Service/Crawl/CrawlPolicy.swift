//Created by Alex Skorulis on 23/6/2026.

import Foundation

enum CrawlPolicy {

    private static let defaultMaxPages = 20
    private static let merivaleBaseURL = URL(string: "https://merivale.com/")!

    static func maxPages(for baseURL: URL) -> Int {
        if URLNormalizer.isSameOrigin(baseURL, as: merivaleBaseURL) {
            return 1
        }
        return defaultMaxPages
    }

    static func shouldUseSitemap(for baseURL: URL) -> Bool {
        !URLNormalizer.isSameOrigin(baseURL, as: merivaleBaseURL)
    }
}
