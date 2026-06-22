//Created by Alex Skorulis on 19/6/2026.

import Foundation
import PDFKit

struct PDFTextExtractionResult: Equatable, Sendable {
    let fullText: String
    let filteredText: String
}

struct PDFTextExtractor {

    /// Set to `true` to use layout-aware PDF markdown generation instead of plain `page.string` extraction.
    static let usesMarkdownParsing = false

    private let markdownGenerator = PDFMarkdownGenerator()

    func extractText(from localURL: URL) -> PDFTextExtractionResult? {
        guard let document = PDFDocument(url: localURL) else {
            return nil
        }

        let pageSeparator = Self.usesMarkdownParsing ? "\n\n---\n\n" : "\n"

        var allParts: [String] = []
        var filteredParts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else {
                continue
            }

            let pageText = pageContent(from: page)
            guard !pageText.isEmpty else {
                continue
            }

            let keywordText = page.string ?? pageText
            allParts.append(pageText)
            if FilterKeywords.containsDealKeyword(keywordText) {
                filteredParts.append(pageText)
            }
        }

        let filteredText = filteredParts.joined(separator: pageSeparator)
        guard !filteredText.isEmpty else {
            return nil
        }

        return PDFTextExtractionResult(
            fullText: allParts.joined(separator: pageSeparator),
            filteredText: filteredText
        )
    }

    private func pageContent(from page: PDFPage) -> String {
        if Self.usesMarkdownParsing {
            return markdownGenerator.markdown(from: page)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
