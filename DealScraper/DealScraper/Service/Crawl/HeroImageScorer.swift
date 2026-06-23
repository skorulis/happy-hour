//Created by Alex Skorulis on 24/6/2026.

import CoreGraphics
import Foundation

nonisolated enum HeroImageScorer {
    static let idealAspectRatio: CGFloat = 1.5
    static let minimumTotalScore: CGFloat = 0.3

    static func aspectScore(width: CGFloat, height: CGFloat) -> CGFloat {
        guard width > 0, height > 0 else { return 0 }
        let ratio = width / height
        return max(0, 1 - abs(ratio - idealAspectRatio) / idealAspectRatio)
    }

    static func textScore(coverageRatio: CGFloat) -> CGFloat {
        1 - min(1, coverageRatio)
    }

    static func totalScore(aspect: CGFloat, text: CGFloat, building: CGFloat) -> CGFloat {
        (aspect + text + building) / 3
    }

    static func isViableCandidate(buildingScore: CGFloat, totalScore: CGFloat) -> Bool {
        buildingScore > 0 || totalScore >= minimumTotalScore
    }
}
