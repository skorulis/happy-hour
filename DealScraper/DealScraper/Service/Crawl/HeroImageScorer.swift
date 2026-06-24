//Created by Alex Skorulis on 24/6/2026.

import CoreGraphics
import Foundation

nonisolated struct HeroImageScore: Equatable {
    let dimensions: CGSize?
    let aspectScore: CGFloat
    let textCoverageRatio: CGFloat
    let textScore: CGFloat
    let buildingScore: CGFloat
    let totalScore: CGFloat
    let isViable: Bool
    let skipReason: String?
}

nonisolated struct RankedHeroImage: Equatable, Identifiable {
    let url: URL
    let score: HeroImageScore
    let rank: Int

    var id: String { "\(rank)-\(url.absoluteString)" }
}

nonisolated enum HeroImageScorer {
    static let idealAspectRatio: CGFloat = 1.5
    static let minimumTotalScore: CGFloat = 0.3

    static func aspectScore(width: CGFloat, height: CGFloat) -> CGFloat {
        return min(width / height, 1.5)
    }

    static func textScore(coverageRatio: CGFloat) -> CGFloat {
        let score = 1 - min(1, coverageRatio)
        return score * score
    }

    static func totalScore(
        aspect: CGFloat,
        text: CGFloat,
        building: CGFloat
    ) -> CGFloat {
        (aspect + text + building) / 3
    }

    static func isViableCandidate(buildingScore: CGFloat, totalScore: CGFloat) -> Bool {
        buildingScore > 0 || totalScore >= minimumTotalScore
    }
}
