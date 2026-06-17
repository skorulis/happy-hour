//Created by Alex Skorulis on 15/6/2026.

import Foundation
import UniformTypeIdentifiers

enum VisionDealInstructions {
    static let posterExtraction = """
        You extract deals from pub and restaurant poster images.

        Critical rule: never rewrite text. Every title, detail, day, and time value must be copied character-for-character as shown on the poster. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.

        Rules:
        - Return one deal per distinct schedule (same days AND times).
        - title: the promotion headline as shown on the poster.
        - details: supporting text for this deal (prices, items, conditions). One poster line per entry.
        - days: text that mentions which days apply, copied as written, e.g. 'EVERY TUES' or 'TUES - THURS 4PM - 6PM / FRI 3PM - 5PM'.
        - times: text that mentions when the deal applies, copied as written, e.g. 'FROM 11:30 TILL SOLD OUT.' or 'TUES - THURS 4PM - 6PM / FRI 3PM - 5PM'. If no time is mentioned, set times to exactly ['all day'].
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
        - Large text is typically the deal title; smaller text is typically supporting details, times, or footers.
        """
}

enum VisionDealImageSupport {
    nonisolated static func mimeType(for url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        guard let type = UTType(filenameExtension: ext),
              type.conforms(to: .image)
        else {
            return nil
        }
        return type.preferredMIMEType
    }
}

enum CursorImageSupport {
    private nonisolated static let supportedMIMETypes: Set<String> = [
        "image/png",
        "image/jpeg",
        "image/gif",
        "image/webp",
    ]

    nonisolated static func isSupported(mimeType: String) -> Bool {
        supportedMIMETypes.contains(mimeType.lowercased())
    }
}

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

enum RemoteVisionDealProcessorError: Swift.Error, Sendable {
    case missingAPIKey
    case missingModel
    case invalidImage
    case networkFailure(underlying: Swift.Error)
    case apiError(statusCode: Int, message: String)
    case decodingFailure
}

enum RemoteVisionDealProcessorSupport {
    nonisolated static func mapClientError(_ error: VisionDealAPI.Error) -> RemoteVisionDealProcessorError {
        switch error {
        case .invalidResponse, .decodingFailure:
            return .decodingFailure
        case let .apiError(statusCode, message):
            return .apiError(statusCode: statusCode, message: message)
        }
    }
}
