//Created by Alex Skorulis on 15/6/2026.

import Foundation

enum VisionDealJSONSupport {
    nonisolated static func parsePayload(from text: String) -> DealExtractionPayload? {
        let trimmed = stripMarkdownFences(from: text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let data = trimmed.data(using: .utf8),
              let payload = try? JSONDecoder().decode(DealExtractionPayload.self, from: data)
        else {
            return nil
        }
        return payload
    }

    nonisolated private static func stripMarkdownFences(from text: String) -> String {
        var result = text
        if result.hasPrefix("```") {
            if let endOfFirstLine = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: endOfFirstLine)...])
            }
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}
