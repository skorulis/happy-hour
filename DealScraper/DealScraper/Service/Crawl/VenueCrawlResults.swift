//Created by Alex Skorulis on 17/6/2026.

import Foundation

struct VenueCrawlResults: Equatable, Sendable {
    let dealsFound: Int
    let visitedPages: [URL]
    let imagesAnalyzed: Int
    let duration: TimeInterval
}
