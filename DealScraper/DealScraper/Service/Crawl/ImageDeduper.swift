//Created by Alex Skorulis on 17/6/2026.

import CoreGraphics
import Foundation

struct ImageDeduper: Sendable {

    let matchThreshold: Double
    let featurePrintDistanceThreshold: Float

    init(matchThreshold: Double = 0.8, featurePrintDistanceThreshold: Float = 0.35) {
        self.matchThreshold = matchThreshold
        self.featurePrintDistanceThreshold = featurePrintDistanceThreshold
    }

    func dedupe(validatedSources: [URL: DiscoveredSource]) -> [URL: DiscoveredSource] {
        var result: [URL: DiscoveredSource] = [:]
        var keptImages: [KeptImage] = []

        for (url, source) in validatedSources {
            guard source.type == .image else {
                result[url] = source
                continue
            }

            let text = normalizedText(from: source.textPieces)
            let featurePrint = source.imageFeaturePrint

            if text.isEmpty && featurePrint == nil {
                result[url] = source
                continue
            }

            if let matchIndex = keptImages.firstIndex(where: {
                isDuplicate(
                    candidateFeaturePrint: featurePrint,
                    candidateText: text,
                    kept: $0
                )
            }) {
                let existing = keptImages[matchIndex]
                if shouldPreferImage(candidate: source, over: existing.source) {
                    result.removeValue(forKey: existing.url)
                    keptImages[matchIndex] = KeptImage(url: url, source: source, text: text, featurePrint: featurePrint)
                    result[url] = source
                }
            } else {
                keptImages.append(KeptImage(url: url, source: source, text: text, featurePrint: featurePrint))
                result[url] = source
            }
        }

        return result
    }

    private struct KeptImage {
        let url: URL
        let source: DiscoveredSource
        let text: String
        let featurePrint: Data?
    }

    private func isDuplicate(
        candidateFeaturePrint: Data?,
        candidateText: String,
        kept: KeptImage
    ) -> Bool {
        if let candidateFeaturePrint,
           let keptFeaturePrint = kept.featurePrint,
           ImageFeaturePrintGenerator.areSimilar(
               candidateFeaturePrint,
               keptFeaturePrint,
               threshold: featurePrintDistanceThreshold
           ) {
            return true
        }

        guard !candidateText.isEmpty, !kept.text.isEmpty else {
            return false
        }

        return textSimilarity(candidateText, kept.text) >= matchThreshold
    }

    private func normalizedText(from textPieces: DealSourceTextPieces?) -> String {
        guard let textPieces else { return "" }
        let lines: [String]
        switch textPieces {
        case let .textLines(textLines):
            lines = textLines
        case let .contentBlocks(blocks):
            lines = blocks.map(\.text)
        }

        return lines
            .map(normalizeLine)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func normalizeLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func textSimilarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        let maxLength = max(a.count, b.count)
        guard maxLength > 0 else { return 1 }
        let distance = levenshteinDistance(a, b)
        return 1 - Double(distance) / Double(maxLength)
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let m = aChars.count
        let n = bChars.count

        if m == 0 { return n }
        if n == 0 { return m }

        var previous = Array(0...n)
        var current = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            current[0] = i
            for j in 1...n {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            swap(&previous, &current)
        }

        return previous[n]
    }

    private func shouldPreferImage(candidate: DiscoveredSource, over existing: DiscoveredSource) -> Bool {
        imageArea(candidate.imageDimensions) > imageArea(existing.imageDimensions)
    }

    private func imageArea(_ dimensions: CGSize?) -> CGFloat {
        guard let dimensions else { return 0 }
        return dimensions.width * dimensions.height
    }
}
