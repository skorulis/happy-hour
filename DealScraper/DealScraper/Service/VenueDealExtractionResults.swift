//Created by Alex Skorulis on 18/6/2026.

import Foundation

struct VenueDealExtractionResults: Equatable, Sendable {
    let dealsFoundBeforeCondensing: Int
    let dealsFound: Int
    let duration: TimeInterval
    let errorCount: Int
}
