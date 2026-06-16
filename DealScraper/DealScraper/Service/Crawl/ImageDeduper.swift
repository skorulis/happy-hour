//Created by Alex Skorulis on 17/6/2026.

import CoreGraphics
import Foundation

struct ImageDeduper: Sendable {

    let matchThreshold: Double
    let lineSimilarityThreshold: Double

    init(matchThreshold: Double = 0.8, lineSimilarityThreshold: Double = 0.9) {
        self.matchThreshold = matchThreshold
        self.lineSimilarityThreshold = lineSimilarityThreshold
    }

    func dedupe(validatedSources: [URL: DiscoveredSource]) -> [URL: DiscoveredSource] {
        var result: [URL: DiscoveredSource] = [:]
        var keptImages: [(url: URL, source: DiscoveredSource, lines: [String])] = []

        for (url, source) in validatedSources {
            guard source.type == .image else {
                result[url] = source
                continue
            }

            let lines = normalizedLines(from: source.textPieces)
            guard !lines.isEmpty else {
                result[url] = source
                continue
            }

            if let matchIndex = keptImages.firstIndex(where: {
                matchPercentage(lines, $0.lines) >= matchThreshold
            }) {
                let existing = keptImages[matchIndex]
                if shouldPreferImage(candidate: source, over: existing.source) {
                    result.removeValue(forKey: existing.url)
                    keptImages[matchIndex] = (url, source, lines)
                    result[url] = source
                }
            } else {
                keptImages.append((url, source, lines))
                result[url] = source
            }
        }

        return result
    }

    private func normalizedLines(from textPieces: DealSourceTextPieces?) -> [String] {
        guard let textPieces else { return [] }
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
    }

    private func normalizeLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func matchPercentage(_ a: [String], _ b: [String]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }

        var unmatchedB = b
        var matched = 0

        for lineA in a {
            guard let matchIndex = unmatchedB.indices.max(by: { lhs, rhs in
                lineSimilarity(lineA, unmatchedB[lhs]) < lineSimilarity(lineA, unmatchedB[rhs])
            }) else { continue }

            if linesMatch(lineA, unmatchedB[matchIndex]) {
                matched += 1
                unmatchedB.remove(at: matchIndex)
            }
        }

        return Double(matched) / Double(max(a.count, b.count))
    }

    private func linesMatch(_ a: String, _ b: String) -> Bool {
        lineSimilarity(a, b) >= lineSimilarityThreshold
    }

    private func lineSimilarity(_ a: String, _ b: String) -> Double {
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
