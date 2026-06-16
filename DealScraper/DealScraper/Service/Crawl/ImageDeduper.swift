//Created by Alex Skorulis on 17/6/2026.

import CoreGraphics
import Foundation

struct ImageDeduper: Sendable {

    let matchThreshold: Double

    init(matchThreshold: Double = 0.8) {
        self.matchThreshold = matchThreshold
    }

    func dedupe(validatedSources: [URL: DiscoveredSource]) -> [URL: DiscoveredSource] {
        var result: [URL: DiscoveredSource] = [:]
        var keptImages: [(url: URL, source: DiscoveredSource, text: String)] = []

        for (url, source) in validatedSources {
            guard source.type == .image else {
                result[url] = source
                continue
            }

            let text = normalizedText(from: source.textPieces)
            guard !text.isEmpty else {
                result[url] = source
                continue
            }

            if let matchIndex = keptImages.firstIndex(where: {
                textSimilarity(text, $0.text) >= matchThreshold
            }) {
                let existing = keptImages[matchIndex]
                if shouldPreferImage(candidate: source, over: existing.source) {
                    result.removeValue(forKey: existing.url)
                    keptImages[matchIndex] = (url, source, text)
                    result[url] = source
                }
            } else {
                keptImages.append((url, source, text))
                result[url] = source
            }
        }

        return result
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
