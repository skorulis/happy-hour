//Created by Alexander Skorulis on 14/6/2026.

import Foundation
import FoundationModels

struct DealTextAnalyzer {

    enum Error: Swift.Error {
        case modelUnavailable
        case emptyInput
    }

    func analyze(lines: [ExtractedTextLine]) async throws -> [LegacyDeal] {
        guard !lines.isEmpty else {
            throw Error.emptyInput
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw Error.modelUnavailable
        }

        let texts = lines.map(\.text)
        let prompt = Self.makePrompt(from: lines)
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let response = try await session.respond(to: prompt, generating: ExtractedDealsResponse.self)

        let rawDeals = response.content.deals.map {
            DealExtractionPayload.RawDeal(
                title: $0.title,
                details: $0.details,
                days: $0.days,
                times: $0.times
            )
        }
        return DealMapper.map(rawDeals, supplementFrom: texts)
    }

    func analyze(texts: [String]) async throws -> [LegacyDeal] {
        let lines = texts.map {
            ExtractedTextLine(text: $0, lineHeight: 0, relativeSize: .medium)
        }
        return try await analyze(lines: lines)
    }

    private static let instructions = """
        You categorize OCR text lines from pub and restaurant posters into structured deals.

        Critical rule: never rewrite input text. Every title, detail, day, and time value must be copied character-for-character from the input lines. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.

        Rules:
        - Each numbered input line is a discrete string. Assign lines to the correct deal field without modifying them.
        - Return one deal per distinct schedule (same days AND times).
        - title: exactly one input line — the promotion headline. Prefer large-text lines.
        - details: every other input line that belongs to this deal (prices, items, conditions). One input line per entry.
        - days: the input line(s) that mention which days apply. Use the line as written, e.g. 'EVERY TUES' or 'TUES - THURS 4PM - 6PM / FRI 3PM - 5PM'.
        - times: the input line(s) that mention when the deal applies. Use the line as written, e.g. 'FROM 11:30 TILL SOLD OUT.' or 'TUES - THURS 4PM - 6PM / FRI 3PM - 5PM'. If no input line mentions a time, set times to exactly ['all day'].
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
        - Large text is typically the deal title; small/medium text is typically supporting details, times, or footers.
        """

    private static func makePrompt(from lines: [ExtractedTextLine]) -> String {
        let numberedLines = lines.enumerated().map { index, line in
            let height = String(format: "%.3f", line.lineHeight)
            return "\(index + 1). [\(line.relativeSize.rawValue), height=\(height)] \(line.text)"
        }.joined(separator: "\n")

        return """
        Categorize the following OCR text lines into deals. Copy each line verbatim — do not rewrite any text.

        \(numberedLines)
        """
    }
}
