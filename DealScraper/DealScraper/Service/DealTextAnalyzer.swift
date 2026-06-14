//Created by Alexander Skorulis on 14/6/2026.

import Foundation
import FoundationModels

struct DealTextAnalyzer {

    enum Error: Swift.Error {
        case modelUnavailable
        case emptyInput
    }

    func analyze(lines: [ExtractedTextLine]) async throws -> [Deal] {
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
            Self.map(deal)
        }.map { Self.supplementTimes(from: texts, into: $0) }
        return Self.merge(mapped)
    }

    func analyze(texts: [String]) async throws -> [Deal] {
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

    private static func map(_ deal: ExtractedDeal) -> Deal? {
        let title = deal.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = deal.details
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !title.isEmpty || !details.isEmpty else { return nil }

        let days = deal.days.flatMap { DealDay.parseAll(in: $0) }
        let times = parseTimes(deal.times)

        return Deal(
            title: title,
            details: details,
            days: days,
            times: times
        )
    }

    private static func parseTimes(_ strings: [String]) -> [DealHours] {
        let trimmed = strings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return [] }

        if trimmed.allSatisfy({ isAllDayToken($0) }) {
            return [.allDay]
        }

        var times: [DealHours] = []
        for string in trimmed {
            if let time = DealHours.parse(string) {
                times.append(time)
            } else {
                times.append(contentsOf: timesInText(string))
            }
        }
        return Array(Set(times))
    }

    private static func isAllDayToken(_ string: String) -> Bool {
        switch string.lowercased() {
        case "all day", "all-day", "allday":
            return true
        default:
            return false
        }
    }

    private static func supplementTimes(from texts: [String], into deal: Deal) -> Deal {
        guard deal.times.isEmpty else { return deal }

        var times: [DealHours] = []
        for text in texts {
            times.append(contentsOf: timesInText(text))
        }

        let resolvedTimes = times.isEmpty ? [DealHours.allDay] : Array(Set(times))

        return Deal(
            title: deal.title,
            details: deal.details,
            days: deal.days,
            times: resolvedTimes
        )
    }

    private static func timesInText(_ text: String) -> [DealHours] {
        if let time = DealHours.parse(text) {
            return [time]
        }

        let pattern = #"(?i)(?<!\d)(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range(at: 1), in: text) else { return nil }
            return DealHours.parse(String(text[matchRange]))
        }
    }

    private static func merge(_ deals: [Deal]) -> [Deal] {
        var merged: [Deal] = []

        for deal in deals {
            if let index = merged.firstIndex(where: { shouldMerge($0, deal) }) {
                let existing = merged[index]
                merged[index] = Deal(
                    title: existing.title.isEmpty ? deal.title : existing.title,
                    details: Array(Set(existing.details + deal.details)),
                    days: Array(Set(existing.days + deal.days)),
                    times: mergedTimes(existing.times, deal.times)
                )
            } else {
                merged.append(deal)
            }
        }

        return merged
    }

    private static func shouldMerge(_ lhs: Deal, _ rhs: Deal) -> Bool {
        let sharedText = Set(dealText(lhs).map { $0.lowercased() })
            .intersection(dealText(rhs).map { $0.lowercased() })
        if !sharedText.isEmpty {
            return true
        }

        if !lhs.times.isEmpty && lhs.times == rhs.times {
            return true
        }

        let sharedDays = Set(lhs.days).intersection(rhs.days)
        guard !sharedDays.isEmpty else { return false }

        return lhs.times.isEmpty || rhs.times.isEmpty || lhs.times == rhs.times
    }

    private static func dealText(_ deal: Deal) -> [String] {
        var text: [String] = []
        if !deal.title.isEmpty {
            text.append(deal.title)
        }
        text.append(contentsOf: deal.details)
        return text
    }

    private static func mergedTimes(_ lhs: [DealHours], _ rhs: [DealHours]) -> [DealHours] {
        if lhs.isEmpty { return rhs }
        if rhs.isEmpty { return lhs }
        if lhs == rhs { return lhs }
        return Array(Set(lhs + rhs))
    }
}
