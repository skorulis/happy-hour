//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct ContentBlockLink: Equatable, Sendable, Codable {
    let text: String?
    let url: URL
}

nonisolated struct ContentBlock: Equatable, Sendable, Codable {
    let title: String?
    let text: String
    let links: [ContentBlockLink]
    
    var fullText: String {
        if let title {
            return "\(title)\n\(text)"
        } else {
            return text
        }
    }

    func formattedOutput(index: Int) -> String {
        var lines: [String] = []
        lines.append("--- Block \(index + 1) ---")
        lines.append("Title: \(title ?? "(none)")")
        lines.append("Text: \(text)")
        if links.isEmpty {
            lines.append("Links: (none)")
        } else {
            lines.append("Links:")
            for link in links {
                lines.append("  - \(link.text ?? ""): \(link.url.absoluteString)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

extension Array where Element == ContentBlock {
    func formattedConsoleOutput() -> String {
        enumerated()
            .map { $0.element.formattedOutput(index: $0.offset) }
            .joined(separator: "\n\n")
    }
}

extension Array where Element == ContentBlockLink {
    func formattedConsoleOutput() -> String {
        enumerated()
            .map { index, link in
                "\(index + 1). \(link.text ?? "(no text)"): \(link.url.absoluteString)"
            }
            .joined(separator: "\n")
    }
}
