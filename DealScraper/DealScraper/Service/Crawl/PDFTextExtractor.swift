//Created by Alex Skorulis on 19/6/2026.

import Foundation
import PDFKit

struct PDFTextExtractionResult: Equatable, Sendable {
    let fullText: String
    let filteredText: String
}

struct PDFTextExtractor {

    func extractText(from localURL: URL) -> PDFTextExtractionResult? {
        guard let document = PDFDocument(url: localURL) else {
            return nil
        }

        var allParts: [String] = []
        var filteredParts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !pageText.isEmpty
            else {
                continue
            }
            allParts.append(pageText)
            if FilterKeywords.containsDealKeyword(pageText) {
                filteredParts.append(pageText)
            }
        }

        let filteredText = filteredParts.joined(separator: "\n")
        guard !filteredText.isEmpty else {
            return nil
        }

        return PDFTextExtractionResult(
            fullText: allParts.joined(separator: "\n"),
            filteredText: filteredText
        )
    }
}
