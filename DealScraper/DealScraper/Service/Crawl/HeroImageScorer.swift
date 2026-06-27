//Created by Alex Skorulis on 24/6/2026.

import CoreGraphics
import Foundation

nonisolated struct HeroImageScore: Equatable {
    let dimensions: CGSize?
    let aspectScore: CGFloat
    let textCoverageRatio: CGFloat
    let textScore: CGFloat
    let buildingScore: CGFloat
    let venueNameScore: CGFloat
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
        building: CGFloat,
        venueName: CGFloat = 0
    ) -> CGFloat {
        (aspect + text + building) / 3 + venueName
    }

    static func namePieces(from venueName: String) -> [String] {
        venueName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    static func venueNameScore(venueName: String, lines: [ExtractedTextLine]) -> CGFloat {
        let pieces = namePieces(from: venueName)
        guard !pieces.isEmpty, !lines.isEmpty else { return 0 }

        let lineTexts = lines.map { $0.text.lowercased() }

        let matchedPieces = pieces.filter { piece in
            lineTexts.contains { containsWord(piece, in: $0) }
        }.count
        let pieceMatchRatio = CGFloat(matchedPieces) / CGFloat(pieces.count)
        guard pieceMatchRatio > 0 else { return 0 }

        let totalCharacters = lineTexts.reduce(0) { $0 + $1.count }
        guard totalCharacters > 0 else { return 0 }

        let nameCharacters = lineTexts
            .filter { line in pieces.contains { containsWord($0, in: line) } }
            .reduce(0) { $0 + $1.count }

        let focusRatio = CGFloat(nameCharacters) / CGFloat(totalCharacters)
        return pieceMatchRatio * focusRatio
    }

    private static func containsWord(_ word: String, in text: String) -> Bool {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .contains(word)
    }

    static func isViableCandidate(buildingScore: CGFloat, totalScore: CGFloat) -> Bool {
        buildingScore > 0 || totalScore >= minimumTotalScore
    }
}
