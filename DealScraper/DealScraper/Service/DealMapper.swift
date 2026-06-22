//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated enum DealMapper {

    nonisolated static func map(
        _ deals: [DealExtractionPayload.RawDeal],
        supplementFrom texts: [String] = []
    ) -> [LegacyDeal] {
        let mapped = deals
            .compactMap { map($0) }
            .map { supplementTimes(from: texts, into: $0) }
        return merge(mapped)
    }

    nonisolated static func map(_ deal: DealExtractionPayload.RawDeal) -> LegacyDeal? {
        let title = deal.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = deal.details
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let conditions = deal.conditions
            .map { normalizeCondition($0) }
            .filter { !$0.isEmpty }
        guard !title.isEmpty || !details.isEmpty || !conditions.isEmpty else { return nil }

        let days = deal.days.flatMap { DealDay.parseAll(in: $0) }
        let times = parseTimes(deal.times)

        return LegacyDeal(
            title: title,
            details: details,
            conditions: conditions,
            days: days,
            times: times
        )
    }

    private static func normalizeCondition(_ string: String) -> String {
        var trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("*") {
            trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
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

    private nonisolated static func supplementTimes(from texts: [String], into deal: LegacyDeal) -> LegacyDeal {
        guard deal.times.isEmpty else { return deal }

        var times: [DealHours] = []
        for text in texts {
            times.append(contentsOf: timesInText(text))
        }

        let resolvedTimes = times.isEmpty ? [DealHours.allDay] : Array(Set(times))

        return LegacyDeal(
            title: deal.title,
            details: deal.details,
            conditions: deal.conditions,
            days: deal.days,
            times: resolvedTimes
        )
    }

    private static func timesInText(_ text: String) -> [DealHours] {
        if let time = DealHours.parse(text) {
            return [time]
        }

        let pattern = #"(?i)(?<!\d)(\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match in
            guard let matchRange = Range(match.range(at: 1), in: text) else { return nil }
            return DealHours.parse(String(text[matchRange]))
        }
    }

    private static func merge(_ deals: [LegacyDeal]) -> [LegacyDeal] {
        var merged: [LegacyDeal] = []

        for deal in deals {
            if let index = merged.firstIndex(where: { shouldMerge($0, deal) }) {
                let existing = merged[index]
                merged[index] = LegacyDeal(
                    title: existing.title.isEmpty ? deal.title : existing.title,
                    details: Array(Set(existing.details + deal.details)),
                    conditions: Array(Set(existing.conditions + deal.conditions)),
                    days: Array(Set(existing.days + deal.days)),
                    times: mergedTimes(existing.times, deal.times)
                )
            } else {
                merged.append(deal)
            }
        }

        return merged
    }

    private static func shouldMerge(_ lhs: LegacyDeal, _ rhs: LegacyDeal) -> Bool {
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

    private static func dealText(_ deal: LegacyDeal) -> [String] {
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
