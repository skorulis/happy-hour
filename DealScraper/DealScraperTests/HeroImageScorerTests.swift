//Created by Alex Skorulis on 24/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct HeroImageScorerTests {

    @Test func aspectScorePrefersThreeToTwoRatio() {
        #expect(
            abs(HeroImageScorer.aspectScore(width: 1500, height: 1000) - HeroImageScorer.idealAspectRatio)
                < 0.001
        )
        #expect(HeroImageScorer.aspectScore(width: 1000, height: 1000) < HeroImageScorer.idealAspectRatio)
        #expect(
            abs(HeroImageScorer.aspectScore(width: 1600, height: 900) - HeroImageScorer.idealAspectRatio)
                < 0.001
        )
        #expect(abs(HeroImageScorer.aspectScore(width: 1000, height: 1000) - 1) < 0.001)
    }

    @Test func textScorePenalizesCoverageQuadratically() {
        #expect(HeroImageScorer.textScore(coverageRatio: 0) == 1)
        #expect(HeroImageScorer.textScore(coverageRatio: 0.5) == 0.25)
        #expect(HeroImageScorer.textScore(coverageRatio: 1) == 0)
        #expect(HeroImageScorer.textScore(coverageRatio: 2) == 0)
    }

    @Test func totalScoreAveragesComponents() {
        #expect(HeroImageScorer.totalScore(aspect: 1, text: 0.5, building: 0.2) == 0.5666666666666666)
    }

    @Test func totalScoreAddsVenueNameBonus() {
        #expect(HeroImageScorer.totalScore(aspect: 1, text: 0.5, building: 0.2, venueName: 1) == 1.5666666666666666)
    }

    @Test func namePiecesSplitsOnNonAlphanumerics() {
        #expect(HeroImageScorer.namePieces(from: "The Toxteth") == ["the", "toxteth"])
        #expect(HeroImageScorer.namePieces(from: "Royal-Hotel & Bar") == ["royal", "hotel", "bar"])
    }

    @Test func venueNameScoreRewardsFocusedNameMatch() {
        let logoLines = [ExtractedTextLine(text: "The Toxteth", lineHeight: 0.1, relativeSize: .large)]
        #expect(abs(HeroImageScorer.venueNameScore(venueName: "The Toxteth", lines: logoLines) - 1) < 0.001)

        let menuLines = [
            ExtractedTextLine(text: "The Toxteth", lineHeight: 0.1, relativeSize: .large),
            ExtractedTextLine(text: "Beer $8", lineHeight: 0.05, relativeSize: .medium),
            ExtractedTextLine(text: "Wine $10", lineHeight: 0.05, relativeSize: .medium),
            ExtractedTextLine(text: "Cocktails $15", lineHeight: 0.05, relativeSize: .medium),
            ExtractedTextLine(text: "Happy Hour 4-6pm", lineHeight: 0.05, relativeSize: .medium),
        ]
        let menuScore = HeroImageScorer.venueNameScore(venueName: "The Toxteth", lines: menuLines)
        #expect(menuScore > 0)
        #expect(menuScore < 0.5)
    }

    @Test func venueNameScoreReturnsZeroWhenNameMissing() {
        let lines = [ExtractedTextLine(text: "Happy Hour Menu", lineHeight: 0.1, relativeSize: .large)]
        #expect(HeroImageScorer.venueNameScore(venueName: "The Toxteth", lines: lines) == 0)
    }

    @Test func venueNameScorePartialPieceMatch() {
        let lines = [ExtractedTextLine(text: "Toxteth", lineHeight: 0.1, relativeSize: .large)]
        #expect(abs(HeroImageScorer.venueNameScore(venueName: "The Toxteth", lines: lines) - 0.5) < 0.001)
    }

    @Test func isViableCandidateRequiresBuildingSignalOrMinimumTotal() {
        #expect(HeroImageScorer.isViableCandidate(buildingScore: 0.1, totalScore: 0.1))
        #expect(HeroImageScorer.isViableCandidate(buildingScore: 0, totalScore: 0.3))
        #expect(!HeroImageScorer.isViableCandidate(buildingScore: 0, totalScore: 0.29))
    }

    @Test func buildingIdentifierMatching() {
        #expect(ImageClassifier.isBuildingRelatedIdentifier("building"))
        #expect(ImageClassifier.isBuildingRelatedIdentifier("skyscraper"))
        #expect(ImageClassifier.isBuildingRelatedIdentifier("house_exterior"))
        #expect(ImageClassifier.isBuildingRelatedIdentifier("structure"))
        #expect(ImageClassifier.isBuildingRelatedIdentifier("facade"))
        #expect(ImageClassifier.isBuildingRelatedIdentifier("architecture"))
        #expect(!ImageClassifier.isBuildingRelatedIdentifier("food"))
        #expect(!ImageClassifier.isBuildingRelatedIdentifier("text"))
    }

    @Test func buildingScoreUsesHighestMatchingConfidence() {
        let classifications: [(identifier: String, confidence: Float)] = [
            (identifier: "food", confidence: 0.9),
            (identifier: "building", confidence: 0.4),
            (identifier: "architecture", confidence: 0.6),
        ]
        let score = ImageClassifier.buildingScore(from: classifications)

        #expect(abs(score - 0.6) < 0.001)
    }
}
