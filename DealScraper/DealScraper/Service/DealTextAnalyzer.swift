//Created by Alexander Skorulis on 14/6/2026.

import Foundation
import FoundationModels

struct DealTextAnalyzer {

    enum Error: Swift.Error {
        case modelUnavailable
        case emptyInput
    }

    func analyze(lines: [ExtractedTextLine]) async throws -> [ExtractionResult] {
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

        let mapped = response.content.deals.compactMap { deal in
            Self.map(deal, allTexts: texts)
        }.map { Self.supplementTimes(from: texts, into: $0) }
        return Self.merge(mapped)
    }

    func analyze(texts: [String]) async throws -> [ExtractionResult] {
        let lines = texts.map {
            ExtractedTextLine(text: $0, lineHeight: 0, relativeSize: .medium)
        }
        return try await analyze(lines: lines)
    }

    private static let instructions = """
        You extract structured deal information from OCR text of pub and restaurant posters.

        Rules:
        - Return one deal per distinct schedule (same days AND times).
        - Put all products sharing that schedule into the products array of one deal.
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses.
        - Output days as full lowercase English day names (monday, tuesday, etc.).
        - Copy time strings verbatim from the poster, including ranges like '4 PM - 6 PM'.
        - If a time appears without AM/PM, include it exactly as written (e.g. '11:30').
        - Large text is typically a deal or section title; small/medium text is typically supporting details, times, or footers. Prefer product names from large text when pairing deals with days/times.
        """

    private static func makePrompt(from lines: [ExtractedTextLine]) -> String {
        let numberedLines = lines.enumerated().map { index, line in
            let height = String(format: "%.3f", line.lineHeight)
            return "\(index + 1). [\(line.relativeSize.rawValue), height=\(height)] \(line.text)"
        }.joined(separator: "\n")

        return """
        Extract all deals from the following OCR text lines:

        \(numberedLines)
        """
    }

    private static func map(_ deal: ExtractedDeal, allTexts: [String]) -> ExtractionResult? {
        let products = deal.products
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !products.isEmpty else { return nil }

        let days = deal.days.compactMap { DealDay.parse($0) }
        let times = deal.times.compactMap { DealTime.parse($0) }

        return ExtractionResult(
            allTexts: allTexts,
            deals: products,
            days: days,
            times: times
        )
    }

    private static func supplementTimes(from texts: [String], into result: ExtractionResult) -> ExtractionResult {
        guard result.times.isEmpty else { return result }

        var times: [DealTime] = []
        for text in texts {
            times.append(contentsOf: timesInText(text))
        }

        guard !times.isEmpty else { return result }

        return ExtractionResult(
            allTexts: result.allTexts,
            deals: result.deals,
            days: result.days,
            times: Array(Set(times))
        )
    }

    private static func timesInText(_ text: String) -> [DealTime] {
        if let time = DealTime.parse(text) {
            return [time]
        }

        let pattern = #"(?i)\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range(at: 1), in: text) else { return nil }
            return DealTime.parse(String(text[matchRange]))
        }
    }

    private static func merge(_ results: [ExtractionResult]) -> [ExtractionResult] {
        var merged: [ExtractionResult] = []

        for result in results {
            if let index = merged.firstIndex(where: { shouldMerge($0, result) }) {
                let existing = merged[index]
                merged[index] = ExtractionResult(
                    allTexts: existing.allTexts,
                    deals: Array(Set(existing.deals + result.deals)),
                    days: Array(Set(existing.days + result.days)),
                    times: mergedTimes(existing.times, result.times)
                )
            } else {
                merged.append(result)
            }
        }

        return merged
    }

    private static func shouldMerge(_ lhs: ExtractionResult, _ rhs: ExtractionResult) -> Bool {
        let sharedProducts = Set(lhs.deals.map { $0.lowercased() })
            .intersection(rhs.deals.map { $0.lowercased() })
        if !sharedProducts.isEmpty {
            return true
        }

        if !lhs.times.isEmpty && lhs.times == rhs.times {
            return true
        }

        let sharedDays = Set(lhs.days).intersection(rhs.days)
        guard !sharedDays.isEmpty else { return false }

        return lhs.times.isEmpty || rhs.times.isEmpty || lhs.times == rhs.times
    }

    private static func mergedTimes(_ lhs: [DealTime], _ rhs: [DealTime]) -> [DealTime] {
        if lhs.isEmpty { return rhs }
        if rhs.isEmpty { return lhs }
        if lhs == rhs { return lhs }
        return Array(Set(lhs + rhs))
    }
}
