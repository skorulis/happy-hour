//Created by Alex Skorulis on 15/6/2026.

import Foundation

struct DiscoveredSource: Equatable, Sendable {
    let url: URL
    let type: DealSourceType
    let imageDimensions: CGSize?
    let textPieces: DealSourceTextPieces?

    init(
        url: URL,
        type: DealSourceType,
        imageDimensions: CGSize? = nil,
        textPieces: DealSourceTextPieces? = nil
    ) {
        self.url = url
        self.type = type
        self.imageDimensions = imageDimensions
        self.textPieces = textPieces
    }
}
