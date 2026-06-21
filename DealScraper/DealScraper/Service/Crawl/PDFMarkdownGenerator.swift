//Created by Alex Skorulis on 22/6/2026.

import Foundation
import PDFKit

struct PDFMarkdownGenerator {

    private let layoutExtractor = PDFLayoutExtractor()

    private enum BlockKind: Equatable {
        case heading
        case paragraph
        case list
    }

    private struct LineBlock: Equatable {
        let lines: [PDFTextLine]
        let kind: BlockKind
    }

    func markdown(from page: PDFPage) -> String {
        let lines = layoutExtractor.lines(from: page)
        guard !lines.isEmpty else {
            return fallbackMarkdown(from: page)
        }

        let bodySize = bodyFontSize(from: lines)
        let headingSizes = headingFontSizes(from: lines, bodySize: bodySize)
        let blocks = groupIntoBlocks(lines: lines, bodySize: bodySize)

        return blocks
            .map { render(block: $0, bodySize: bodySize, headingSizes: headingSizes) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private func fallbackMarkdown(from page: PDFPage) -> String {
        guard let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else {
            return ""
        }
        return text
    }

    private func groupIntoBlocks(lines: [PDFTextLine], bodySize: CGFloat) -> [LineBlock] {
        guard !lines.isEmpty else { return [] }

        let lineHeights = lines.map { max($0.bounds.height, 1) }
        let medianHeight = median(lineHeights) ?? 12

        var blocks: [LineBlock] = []
        var paragraphLines: [PDFTextLine] = []
        var listLines: [PDFTextLine] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(LineBlock(lines: paragraphLines, kind: .paragraph))
            paragraphLines = []
        }

        func flushList() {
            guard !listLines.isEmpty else { return }
            blocks.append(LineBlock(lines: listLines, kind: .list))
            listLines = []
        }

        for line in lines {
            let text = layoutExtractor.lineText(from: line)

            if isHeading(line: line, text: text, bodySize: bodySize) {
                flushParagraph()
                flushList()
                blocks.append(LineBlock(lines: [line], kind: .heading))
                continue
            }

            if isListItem(text) {
                flushParagraph()
                listLines.append(line)
                continue
            }

            flushList()

            if let lastLine = paragraphLines.last {
                let gap = lastLine.bounds.minY - line.bounds.maxY
                if gap > medianHeight * 1.2 {
                    flushParagraph()
                }
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        flushList()
        return blocks
    }

    private func render(block: LineBlock, bodySize: CGFloat, headingSizes: [CGFloat]) -> String {
        switch block.kind {
        case .heading:
            guard let line = block.lines.first else { return "" }
            let text = layoutExtractor.lineText(from: line)
            let level = headingLevel(fontSize: line.averageFontSize, headingSizes: headingSizes)
            return String(repeating: "#", count: level) + " " + text

        case .paragraph:
            return block.lines
                .map { layoutExtractor.lineText(from: $0) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

        case .list:
            return block.lines
                .map { markdownListLine(from: layoutExtractor.lineText(from: $0)) }
                .joined(separator: "\n")
        }
    }

    private func markdownListLine(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return trimmed
        }

        if let match = trimmed.firstMatch(of: /^(\d+[.)])\s*(.+)/) {
            return "\(match.1) \(match.2)"
        }

        if let first = trimmed.first, ["•", "·", "*", "-"].contains(first) {
            let remainder = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            return "- \(remainder)"
        }

        return "- \(trimmed)"
    }

    private func isHeading(line: PDFTextLine, text: String, bodySize: CGFloat) -> Bool {
        guard !text.isEmpty, text.count <= 80, !text.contains("\n") else { return false }

        if line.averageFontSize >= bodySize * 1.25 {
            return true
        }

        let letters = text.filter(\.isLetter)
        if !letters.isEmpty, letters.allSatisfy(\.isUppercase) {
            return true
        }

        if line.isBold, line.averageFontSize >= bodySize * 1.25 {
            return true
        }

        return false
    }

    private func isListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return true
        }

        if let first = trimmed.first, ["•", "·"].contains(first) {
            return true
        }

        return trimmed.firstMatch(of: /^\d+[.)]\s/) != nil
    }

    private func bodyFontSize(from lines: [PDFTextLine]) -> CGFloat {
        let roundedSizes = lines.map { round($0.averageFontSize * 2) / 2 }
        var counts: [CGFloat: Int] = [:]
        for size in roundedSizes {
            counts[size, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let modes = counts.filter { $0.value == maxCount }.map(\.key)
        return modes.min() ?? (roundedSizes.first ?? 12)
    }

    private func headingFontSizes(from lines: [PDFTextLine], bodySize: CGFloat) -> [CGFloat] {
        let sizes = lines
            .filter { isHeading(line: $0, text: layoutExtractor.lineText(from: $0), bodySize: bodySize) }
            .map { round($0.averageFontSize * 2) / 2 }
        return Array(Set(sizes)).sorted(by: >)
    }

    private func headingLevel(fontSize: CGFloat, headingSizes: [CGFloat]) -> Int {
        guard let index = headingSizes.firstIndex(where: { abs($0 - fontSize) < 0.6 }) else {
            return 2
        }
        if headingSizes.count == 1 {
            return 2
        }
        return min(index + 1, 3)
    }

    private func median(_ values: [CGFloat]) -> CGFloat? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}
