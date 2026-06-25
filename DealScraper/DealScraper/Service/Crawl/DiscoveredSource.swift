//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct DiscoveredSource: Equatable, Sendable {
    let url: URL
    let sourceURL: URL
    let type: DealSourceType
    let imageDimensions: CGSize?
    let textPieces: DealSourceTextPieces?
    let imageFeaturePrint: Data?
    let contentHash: String?

    init(
        url: URL,
        sourceURL: URL,
        type: DealSourceType,
        imageDimensions: CGSize? = nil,
        textPieces: DealSourceTextPieces? = nil,
        imageFeaturePrint: Data? = nil,
        contentHash: String? = nil
    ) {
        self.url = url
        self.sourceURL = sourceURL
        self.type = type
        self.imageDimensions = imageDimensions
        self.textPieces = textPieces
        self.imageFeaturePrint = imageFeaturePrint
        self.contentHash = contentHash
    }
}
