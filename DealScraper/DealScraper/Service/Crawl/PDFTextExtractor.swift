//Created by Alex Skorulis on 19/6/2026.

import Foundation
import PDFKit

struct PDFTextExtractionResult: Equatable, Sendable {
    let fullMarkdown: String
    let filteredMarkdown: String

    var fullText: String { plainText(from: fullMarkdown) }
    var filteredText: String { plainText(from: filteredMarkdown) }

    private func plainText(from markdown: String) -> String {
        markdown
            .replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[-*]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n---\n", with: "\n")
    }
}

struct PDFTextExtractor {

    private let markdownGenerator = PDFMarkdownGenerator()
    private static let pageSeparator = "\n\n---\n\n"

    func extractText(from localURL: URL) -> PDFTextExtractionResult? {
        guard let document = PDFDocument(url: localURL) else {
            return nil
        }

        var allParts: [String] = []
        var filteredParts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else {
                continue
            }

            let pageMarkdown = markdownGenerator.markdown(from: page)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !pageMarkdown.isEmpty else {
                continue
            }

            let keywordText = page.string ?? pageMarkdown
            allParts.append(pageMarkdown)
            if FilterKeywords.containsDealKeyword(keywordText) {
                filteredParts.append(pageMarkdown)
            }
        }

        let filteredMarkdown = filteredParts.joined(separator: Self.pageSeparator)
        guard !filteredMarkdown.isEmpty else {
            return nil
        }

        return PDFTextExtractionResult(
            fullMarkdown: allParts.joined(separator: Self.pageSeparator),
            filteredMarkdown: filteredMarkdown
        )
    }
}
