//Created by Alex Skorulis on 18/6/2026.

import Demark
import Foundation

enum WebMarkdownGeneratorError: LocalizedError {
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "The page HTML contained no convertible content."
        }
    }
}

@MainActor
final class WebMarkdownGenerator {

    private let demark: Demark

    init() {
        self.demark = Demark()
    }

    func markdown(from html: String) async throws -> String {
        let trimmedHTML = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHTML.isEmpty else {
            throw WebMarkdownGeneratorError.emptyContent
        }

        let markdown = try await demark.convertToMarkdown(trimmedHTML)

        let trimmedMarkdown = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMarkdown.isEmpty {
            throw WebMarkdownGeneratorError.emptyContent
        }
        return trimmedMarkdown
    }
}
