//  Created by Alexander Skorulis on 14/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Vision

struct DealImageExtractor {

    enum Error: Swift.Error {
        case invalidImage
        case recognitionFailed
    }

    private static let largeSizeThreshold: CGFloat = 0.75
    private static let mediumSizeThreshold: CGFloat = 0.45

    nonisolated func extractTexts(from url: URL) async throws -> [ExtractedTextLine] {
        guard let cgImage = Self.loadCGImage(from: url) else {
            throw Error.invalidImage
        }
        return try await extractTexts(from: cgImage)
    }

    nonisolated func extractTexts(from cgImage: CGImage) async throws -> [ExtractedTextLine] {
        try await Task.detached {
            try Self.performRecognition(on: cgImage)
        }.value
    }

    private nonisolated static func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private nonisolated static func performRecognition(on cgImage: CGImage) throws -> [ExtractedTextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-AU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw Error.recognitionFailed
        }

        guard let observations = request.results else {
            return []
        }

        let fragments = observations.compactMap { observation -> TextFragment? in
            let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text, !text.isEmpty else { return nil }
            return TextFragment(text: text, boundingBox: observation.boundingBox)
        }

        let lines = groupIntoLines(fragments).map { line -> ExtractedTextLine in
            let text = line.map(\.text).joined(separator: " ")
            let lineHeight = line.map(\.boundingBox.height).max() ?? 0
            return ExtractedTextLine(text: text, lineHeight: lineHeight, relativeSize: .medium)
        }

        return assignRelativeSizes(to: lines)
    }

    private static func assignRelativeSizes(to lines: [ExtractedTextLine]) -> [ExtractedTextLine] {
        guard let maxHeight = lines.map(\.lineHeight).max(), maxHeight > 0 else {
            return lines
        }

        return lines.map { line in
            let ratio = line.lineHeight / maxHeight
            let relativeSize: RelativeTextSize
            if ratio >= largeSizeThreshold {
                relativeSize = .large
            } else if ratio >= mediumSizeThreshold {
                relativeSize = .medium
            } else {
                relativeSize = .small
            }
            return ExtractedTextLine(
                text: line.text,
                lineHeight: line.lineHeight,
                relativeSize: relativeSize
            )
        }
    }

    private struct TextFragment {
        let text: String
        let boundingBox: CGRect
    }

    private static func groupIntoLines(_ fragments: [TextFragment]) -> [[TextFragment]] {
        guard !fragments.isEmpty else { return [] }

        let sorted = fragments.sorted { lhs, rhs in
            if !belongsToLine(lhs.boundingBox, line: [rhs]) {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }
            return lhs.boundingBox.origin.x < rhs.boundingBox.origin.x
        }

        var lines: [[TextFragment]] = []
        var currentLine = [sorted[0]]

        for fragment in sorted.dropFirst() {
            if belongsToLine(fragment.boundingBox, line: currentLine) {
                currentLine.append(fragment)
            } else {
                lines.append(sortLineLeftToRight(currentLine))
                currentLine = [fragment]
            }
        }

        lines.append(sortLineLeftToRight(currentLine))
        return lines
    }

    private static func sortLineLeftToRight(_ line: [TextFragment]) -> [TextFragment] {
        line.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
    }

    private static func belongsToLine(_ box: CGRect, line: [TextFragment]) -> Bool {
        let lineMinY = line.map(\.boundingBox.minY).min() ?? box.minY
        let lineMaxY = line.map(\.boundingBox.maxY).max() ?? box.maxY
        let lineBox = CGRect(x: 0, y: lineMinY, width: 1, height: lineMaxY - lineMinY)

        let overlap = verticalOverlap(box, lineBox)
        let minHeight = min(box.height, lineBox.height)
        guard minHeight > 0 else {
            return abs(box.midY - lineBox.midY) < 0.01
        }
        return overlap / minHeight >= 0.5
    }

    private static func verticalOverlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        max(0, min(a.maxY, b.maxY) - max(a.minY, b.minY))
    }
}
