//Created by Alex Skorulis on 22/6/2026.

import AppKit
import Foundation
import PDFKit

struct PDFTextRun: Equatable, Sendable {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat
    let isBold: Bool
    let isItalic: Bool
}

struct PDFTextLine: Equatable, Sendable {
    let runs: [PDFTextRun]

    var bounds: CGRect {
        runs.reduce(CGRect.null) { partial, run in
            partial.isNull ? run.bounds : partial.union(run.bounds)
        }
    }

    var averageFontSize: CGFloat {
        guard !runs.isEmpty else { return 12 }
        return runs.map(\.fontSize).reduce(0, +) / CGFloat(runs.count)
    }

    var isBold: Bool {
        !runs.isEmpty && runs.allSatisfy(\.isBold)
    }
}

struct PDFLayoutExtractor {

    private let lineYTolerance: CGFloat = 4
    private let runGapThreshold: CGFloat = 2
    private let lineColumnGapThreshold: CGFloat = 40

    func lines(from page: PDFPage) -> [PDFTextLine] {
        guard let attributedString = page.attributedString, attributedString.length > 0 else {
            return []
        }

        var runs: [PDFTextRun] = []
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string
            guard !substring.isEmpty else { return }

            let font = (attributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 12)
            let traits = font.fontDescriptor.symbolicTraits
            let isBold = traits.contains(.bold)
            let isItalic = traits.contains(.italic)

            let parts = splitIntoLineParts(substring)
            var locationOffset = 0
            for part in parts {
                defer { locationOffset += part.utf16.count + 1 }
                guard !part.isEmpty, !part.allSatisfy(\.isWhitespace) else { continue }

                let partRange = NSRange(
                    location: range.location + locationOffset,
                    length: part.utf16.count
                )
                guard let selection = page.selection(for: partRange) else { continue }
                let bounds = selection.bounds(for: page)
                guard bounds.width > 0, bounds.height > 0 else { continue }

                runs.append(
                    PDFTextRun(
                        text: part,
                        bounds: bounds,
                        fontSize: font.pointSize,
                        isBold: isBold,
                        isItalic: isItalic
                    )
                )
            }
        }

        guard !runs.isEmpty else { return [] }

        let pageWidth = page.bounds(for: .mediaBox).width
        let columns = PDFColumnLayout.detect(from: runs, pageWidth: pageWidth)
        var runsByColumn = Array(repeating: [PDFTextRun](), count: max(columns.anchors.count, 1))
        for run in runs {
            let columnIndex = columns.index(for: run)
            runsByColumn[columnIndex].append(run)
        }

        var groupedLines: [PDFTextLine] = []
        for columnRuns in runsByColumn {
            groupedLines.append(contentsOf: groupRunsIntoLines(columnRuns))
        }

        return groupedLines
    }

    private func groupRunsIntoLines(_ runs: [PDFTextRun]) -> [PDFTextLine] {
        guard !runs.isEmpty else { return [] }

        let sortedRuns = runs.sorted { lhs, rhs in
            let yDelta = abs(lhs.bounds.midY - rhs.bounds.midY)
            if yDelta > lineYTolerance {
                return lhs.bounds.midY > rhs.bounds.midY
            }
            return lhs.bounds.minX < rhs.bounds.minX
        }

        var groupedLines: [PDFTextLine] = []
        var currentRuns: [PDFTextRun] = []
        var currentY: CGFloat?

        for run in sortedRuns {
            let centerY = run.bounds.midY
            if let y = currentY, abs(centerY - y) <= lineYTolerance {
                if let lastRun = currentRuns.last,
                   shouldSplitLine(between: lastRun, and: run)
                   || shouldSplitLineHorizontally(between: lastRun, and: run)
                {
                    groupedLines.append(PDFTextLine(runs: sortRunsLeftToRight(currentRuns)))
                    currentRuns = [run]
                    currentY = centerY
                } else {
                    currentRuns.append(run)
                }
            } else {
                if !currentRuns.isEmpty {
                    groupedLines.append(PDFTextLine(runs: sortRunsLeftToRight(currentRuns)))
                }
                currentRuns = [run]
                currentY = centerY
            }
        }

        if !currentRuns.isEmpty {
            groupedLines.append(PDFTextLine(runs: sortRunsLeftToRight(currentRuns)))
        }

        return groupedLines
    }

    func lineText(from line: PDFTextLine) -> String {
        var parts: [String] = []
        var previousRun: PDFTextRun?

        for run in line.runs {
            let text = run.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            if let previousRun {
                let gap = run.bounds.minX - previousRun.bounds.maxX
                if gap > runGapThreshold, let last = parts.last, !last.hasSuffix(" ") {
                    parts.append(" ")
                }
            }

            parts.append(text)
            previousRun = run
        }

        return normalizedText(parts.joined())
    }

    private func shouldSplitLine(between lhs: PDFTextRun, and rhs: PDFTextRun) -> Bool {
        let larger = max(lhs.fontSize, rhs.fontSize)
        let smaller = min(lhs.fontSize, rhs.fontSize)
        guard smaller > 0 else { return false }
        return larger / smaller >= 1.25
    }

    private func shouldSplitLineHorizontally(between lhs: PDFTextRun, and rhs: PDFTextRun) -> Bool {
        let gap = rhs.bounds.minX - lhs.bounds.maxX
        return gap > lineColumnGapThreshold
    }

    private func splitIntoLineParts(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }

    private func sortRunsLeftToRight(_ runs: [PDFTextRun]) -> [PDFTextRun] {
        runs.sorted { $0.bounds.minX < $1.bounds.minX }
    }

    private func normalizedText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
