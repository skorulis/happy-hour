//Created by Alex Skorulis on 19/6/2026.

import Foundation
import PDFKit

struct PDFTextExtractor {

    func extractText(from localURL: URL) -> String? {
        guard let document = PDFDocument(url: localURL) else {
            return nil
        }

        var parts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !pageText.isEmpty
            else {
                continue
            }
            parts.append(pageText)
        }

        let text = parts.joined(separator: "\n")
        return text.isEmpty ? nil : text
    }
}
