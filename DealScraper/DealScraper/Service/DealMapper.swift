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
        var title = DealTextNormalizer.prepareTitle(deal.title)
        var details = DealTextNormalizer.prepareDetails(deal.details)
        guard let dayResolved = resolveDayInTitle(title: title, details: details) else { return nil }
        (title, details) = dayResolved
        (title, details) = withPriceOnlyTitle(title: title, details: details)
        (title, details) = withLeadingPriceInTitle(title: title, details: details)
        title = stripTimeFromTitle(title)
        title = DealTextNormalizer.formatTitle(title)
        if !title.isEmpty, FilterKeywords.containsExcludedKeyword(title) {
            return nil
        }
        details = DealTextNormalizer.normalizeDetails(details)
        let conditions = DealTextNormalizer.normalizeConditions(deal.conditions)
        guard !title.isEmpty || !details.isEmpty || !conditions.isEmpty else { return nil }

        let days = DealDay.parseAll(in: normalizedDayStrings(deal.days))
        let times = DealTimeParser.parse(deal.times)

        return deduplicated(
            LegacyDeal(
                title: title,
                details: details,
                conditions: conditions,
                days: days,
                times: times
            )
        )
    }

    private static func normalizedDayStrings(_ days: [String]) -> [String] {
        days.map { day in
            day.replacingOccurrences(
                of: #"(?i)\bthrough\b"#,
                with: "to",
                options: .regularExpression
            )
        }
    }

    private static func resolveDayInTitle(title: String, details: [String]) -> (title: String, details: [String])? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if DealDay.parse(trimmedTitle) != nil {
            guard let (firstLine, remainingDetails) = popFirstDetailLine(from: details) else {
                return nil
            }
            return (firstLine, remainingDetails)
        }

        var resolvedTitle = stripDayWord(from: trimmedTitle, atStart: true)
        resolvedTitle = stripDayWord(from: resolvedTitle, atStart: false)
        resolvedTitle = resolvedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return (resolvedTitle, details)
    }

    private static func stripDayWord(from title: String, atStart: Bool) -> String {
        let parts = title.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !parts.isEmpty else { return title }

        if atStart {
            guard DealDay.parse(parts[0]) != nil else { return title }
            return parts.dropFirst().joined(separator: " ")
        }

        guard parts.count > 1, DealDay.parse(parts[parts.count - 1]) != nil else { return title }
        return parts.dropLast().joined(separator: " ")
    }

    private static func withPriceOnlyTitle(title: String, details: [String]) -> (title: String, details: [String]) {
        guard DealTextNormalizer.isPriceLine(title), let (firstLine, remainingDetails) = popFirstDetailLine(from: details) else {
            return (title, details)
        }

        let resolvedTitle: String
        if DealTextNormalizer.comparisonKey(title).contains(DealTextNormalizer.comparisonKey(firstLine)) {
            resolvedTitle = title
        } else {
            resolvedTitle = "\(title) \(firstLine)"
        }

        return (resolvedTitle, remainingDetails)
    }

    private static func popFirstDetailLine(from details: [String]) -> (line: String, remaining: [String])? {
        for (index, detail) in details.enumerated() {
            let lines = detail.components(separatedBy: .newlines)
            for (lineIndex, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                var remaining = details
                remaining.remove(at: index)

                let trailingLines = lines[(lineIndex + 1)...]
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !trailingLines.isEmpty {
                    remaining.insert(trailingLines, at: index)
                }

                return (trimmed, remaining)
            }
        }
        return nil
    }

    private static func withLeadingPriceInTitle(title: String, details: [String]) -> (title: String, details: [String]) {
        guard let firstDetail = details.first, DealTextNormalizer.isPriceLine(firstDetail) else {
            return (title, details)
        }

        let resolvedTitle: String
        if title.isEmpty {
            resolvedTitle = firstDetail
        } else if DealTextNormalizer.comparisonKey(title).contains(DealTextNormalizer.comparisonKey(firstDetail)) {
            resolvedTitle = title
        } else {
            resolvedTitle = "\(title) \(firstDetail)"
        }

        return (resolvedTitle, Array(details.dropFirst()))
    }

    private static func deduplicated(_ deal: LegacyDeal) -> LegacyDeal {
        let titleKey = DealTextNormalizer.comparisonKey(deal.title)
        var excludeForDetails = Set<String>()
        if !titleKey.isEmpty {
            excludeForDetails.insert(titleKey)
        }

        let details = deduplicatedLines(deal.details, excluding: excludeForDetails)
        let detailKeys = Set(details.map(DealTextNormalizer.comparisonKey).filter { !$0.isEmpty })
        let excludeForConditions = excludeForDetails.union(detailKeys)
        let conditions = deduplicatedLines(deal.conditions, excluding: excludeForConditions)

        return LegacyDeal(
            title: deal.title,
            details: details,
            conditions: conditions,
            days: deal.days,
            times: deal.times
        )
    }

    private static func deduplicatedLines(_ lines: [String], excluding excluded: Set<String>) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for line in lines {
            let key = DealTextNormalizer.comparisonKey(line)
            guard !key.isEmpty, !excluded.contains(key), !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(line)
        }
        return result
    }

    private static func stripTimeFromTitle(_ title: String) -> String {
        var result = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return result }

        let time = #"(?:\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?|\d{3,4}\s*(?:am|pm))"#
        let availableFromPattern = #"(?i)\s+available\s+from\s+(\#(time))\s*$"#
        if let stripped = stripSuffix(matching: availableFromPattern, in: result, timeCaptureGroup: 1) {
            result = stripped
        }

        let trailingTimePattern = #"(?i)\s+(\#(time))\s*$"#
        if let stripped = stripSuffix(matching: trailingTimePattern, in: result, timeCaptureGroup: 1) {
            result = stripped
        }

        return stripTrailingFromWord(from: result)
    }

    private static func stripTrailingFromWord(from title: String) -> String {
        let parts = title.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard parts.count > 1, parts.last?.caseInsensitiveCompare("from") == .orderedSame else {
            return title
        }
        return parts.dropLast().joined(separator: " ")
    }

    private static func stripSuffix(
        matching pattern: String,
        in text: String,
        timeCaptureGroup: Int
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let matchRange = Range(match.range, in: text),
              let timeRange = Range(match.range(at: timeCaptureGroup), in: text)
        else {
            return nil
        }

        let timeText = String(text[timeRange])
        guard DealHours.toMinutes(string: timeText) != nil else { return nil }

        return String(text[..<matchRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private nonisolated static func supplementTimes(from texts: [String], into deal: LegacyDeal) -> LegacyDeal {
        guard deal.times.isEmpty else { return deal }

        var times: [DealHours] = []
        for text in texts {
            times.append(contentsOf: DealTimeParser.timesInText(text))
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

    private static func merge(_ deals: [LegacyDeal]) -> [LegacyDeal] {
        var merged: [LegacyDeal] = []

        for deal in deals {
            if let index = merged.firstIndex(where: { shouldMerge($0, deal) }) {
                let existing = merged[index]
                merged[index] = deduplicated(
                    LegacyDeal(
                        title: existing.title.isEmpty ? deal.title : existing.title,
                        details: existing.details + deal.details,
                        conditions: existing.conditions + deal.conditions,
                        days: Array(Set(existing.days + deal.days)),
                        times: mergedTimes(existing.times, deal.times)
                    )
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

        // Matching times alone are not enough to merge: distinct deals (e.g. a happy
        // hour and a cocktail special) often run in the same window but describe
        // different products. Only combine deals that share a day and where one side
        // is missing times, so the incomplete deal can inherit the other's window.
        let sharedDays = Set(lhs.days).intersection(rhs.days)
        guard !sharedDays.isEmpty else { return false }

        return lhs.times.isEmpty || rhs.times.isEmpty
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
