//Created by Alex Skorulis on 17/6/2026.

import Foundation

nonisolated struct VenueDealSourceMaterial: Sendable {
    let index: Int
    let dealSourceId: Int64
    let url: URL
    let sourceURL: URL
    let type: DealSourceType
    let pngData: Data?
    let markdown: String?
}
