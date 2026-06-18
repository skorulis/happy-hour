//Created by Alex Skorulis on 18/6/2026.

import Foundation

struct DealCondenser: Sendable {

    let matchThreshold: Double

    init(matchThreshold: Double = 0.75) {
        self.matchThreshold = matchThreshold
    }

    func condense(_ deals: [DealWithSchedules]) -> [DealWithSchedules] {
        var merged: [DealWithSchedules] = []

        for deal in deals {
            if let index = merged.firstIndex(where: { shouldMerge($0, deal) }) {
                merged[index] = combine(merged[index], deal)
            } else {
                merged.append(deal)
            }
        }

        return merged
    }

    private func shouldMerge(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> Bool {
        if hasExactSharedLine(lhs, rhs) {
            return true
        }

        let lhsText = normalizedText(for: lhs)
        let rhsText = normalizedText(for: rhs)

        if hasSubstringContainment(lhsText: lhsText, rhsText: rhsText) {
            return !hasScheduleConflict(lhs, rhs, strongTextMatch: true)
        }

        if textSimilarity(lhsText, rhsText) >= matchThreshold,
           hasTokenOverlap(lhs, rhs) {
            return !hasScheduleConflict(lhs, rhs, strongTextMatch: true)
        }

        if schedulesOverlap(lhs.schedules, rhs.schedules),
           hasTokenOverlap(lhs, rhs) {
            return !hasScheduleConflict(lhs, rhs, strongTextMatch: false)
        }

        return false
    }

    private func combine(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> DealWithSchedules {
        let lhsDeal = lhs.deal
        let rhsDeal = rhs.deal

        let title = preferredTitle(lhsDeal.title, rhsDeal.title)
        let details = mergedLines(lhsDeal.details, rhsDeal.details)
        let conditions = mergedLines(lhsDeal.conditions, rhsDeal.conditions)
        let imageURL = lhsDeal.imageURL ?? rhsDeal.imageURL
        let sourceURL = preferredSourceURL(lhsDeal, rhsDeal)

        let deal = Deal(
            id: lhsDeal.id,
            venueId: lhsDeal.venueId,
            title: title,
            imageURL: imageURL,
            sourceURL: sourceURL,
            details: details,
            conditions: conditions
        )

        let schedules = mergedSchedules(lhs.schedules, rhs.schedules)
        return DealWithSchedules(deal: deal, schedules: schedules)
    }

    private func normalizedText(for item: DealWithSchedules) -> String {
        textLines(for: item)
            .map(normalizeLine)
            .joined(separator: " ")
    }

    private func textLines(for item: DealWithSchedules) -> [String] {
        var lines: [String] = []
        if let title = item.deal.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            lines.append(title)
        }
        lines.append(contentsOf: splitLines(item.deal.details))
        lines.append(contentsOf: splitLines(item.deal.conditions))
        return lines
    }

    private func splitLines(_ text: String?) -> [String] {
        guard let text else { return [] }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizeLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func hasExactSharedLine(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> Bool {
        let lhsLines = Set(textLines(for: lhs).map(normalizeLine).filter { !$0.isEmpty })
        let rhsLines = Set(textLines(for: rhs).map(normalizeLine).filter { !$0.isEmpty })
        return !lhsLines.intersection(rhsLines).isEmpty
    }

    private func significantTokens(from text: String) -> Set<String> {
        let stopWords: Set<String> = [
            "a", "an", "and", "are", "at", "be", "by", "day", "deal", "every", "for", "from",
            "happy", "hour", "in", "is", "of", "on", "or", "special", "the", "to", "with",
        ]

        return Set(
            text
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
                .filter { token in
                    if token.contains("$") || token.contains(where: \.isNumber) {
                        return true
                    }
                    let lower = token.lowercased()
                    return lower.count >= 3 && !stopWords.contains(lower)
                }
        )
    }

    private func hasSubstringContainment(lhsText: String, rhsText: String) -> Bool {
        let lhsTokens = significantTokens(from: lhsText)
        let rhsTokens = significantTokens(from: rhsText)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return false }

        let (shorter, longer) = lhsTokens.count <= rhsTokens.count
            ? (lhsTokens, rhsTokens)
            : (rhsTokens, lhsTokens)
        return shorter.isSubset(of: longer)
    }

    private func hasTokenOverlap(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> Bool {
        let lhsTokens = significantTokens(from: normalizedText(for: lhs))
        let rhsTokens = significantTokens(from: normalizedText(for: rhs))
        return !lhsTokens.intersection(rhsTokens).isEmpty
    }

    private func schedulesOverlap(_ lhs: [DealSchedule], _ rhs: [DealSchedule]) -> Bool {
        for left in lhs {
            for right in rhs where left.dayOfWeek == right.dayOfWeek {
                if left.startMinute == right.startMinute && left.endMinute == right.endMinute {
                    return true
                }
                if rangesOverlap(
                    start: left.startMinute,
                    end: left.endMinute,
                    otherStart: right.startMinute,
                    otherEnd: right.endMinute
                ) {
                    return true
                }
            }
        }
        return false
    }

    private func hasScheduleConflict(
        _ lhs: DealWithSchedules,
        _ rhs: DealWithSchedules,
        strongTextMatch: Bool
    ) -> Bool {
        guard !lhs.schedules.isEmpty, !rhs.schedules.isEmpty else { return false }

        var hasSharedDay = false
        for left in lhs.schedules {
            for right in rhs.schedules where left.dayOfWeek == right.dayOfWeek {
                hasSharedDay = true
                if left.startMinute == right.startMinute && left.endMinute == right.endMinute {
                    return false
                }
                if rangesOverlap(
                    start: left.startMinute,
                    end: left.endMinute,
                    otherStart: right.startMinute,
                    otherEnd: right.endMinute
                ) {
                    return false
                }
            }
        }

        guard hasSharedDay else { return false }
        if strongTextMatch { return false }
        return true
    }

    private func rangesOverlap(start: Int, end: Int, otherStart: Int, otherEnd: Int) -> Bool {
        start < otherEnd && end > otherStart
    }

    private func textSimilarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        let maxLength = max(a.count, b.count)
        guard maxLength > 0 else { return 1 }
        let distance = levenshteinDistance(a, b)
        return 1 - Double(distance) / Double(maxLength)
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let m = aChars.count
        let n = bChars.count

        if m == 0 { return n }
        if n == 0 { return m }

        var previous = Array(0...n)
        var current = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            current[0] = i
            for j in 1...n {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            swap(&previous, &current)
        }

        return previous[n]
    }

    private func preferredTitle(_ lhs: String?, _ rhs: String?) -> String? {
        let lhsTrimmed = lhs?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rhsTrimmed = rhs?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if lhsTrimmed.isEmpty { return rhsTrimmed.isEmpty ? nil : rhsTrimmed }
        if rhsTrimmed.isEmpty { return lhsTrimmed }

        return lhsTrimmed.count >= rhsTrimmed.count ? lhsTrimmed : rhsTrimmed
    }

    private func mergedLines(_ lhs: String?, _ rhs: String?) -> String? {
        let lines = uniqueLines(splitLines(lhs) + splitLines(rhs))
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private func uniqueLines(_ lines: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for line in lines {
            let key = normalizeLine(line)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(line)
        }
        return result
    }

    private func preferredSourceURL(_ lhs: Deal, _ rhs: Deal) -> String? {
        if lhs.imageURL == nil, rhs.imageURL != nil {
            return lhs.sourceURL ?? rhs.sourceURL
        }
        if rhs.imageURL == nil, lhs.imageURL != nil {
            return rhs.sourceURL ?? lhs.sourceURL
        }
        return lhs.sourceURL ?? rhs.sourceURL
    }

    private func mergedSchedules(_ lhs: [DealSchedule], _ rhs: [DealSchedule]) -> [DealSchedule] {
        var seen: Set<ScheduleKey> = []
        var result: [DealSchedule] = []

        for schedule in lhs + rhs {
            let key = ScheduleKey(
                dayOfWeek: schedule.dayOfWeek,
                startMinute: schedule.startMinute,
                endMinute: schedule.endMinute
            )
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(
                DealSchedule(
                    id: schedule.id,
                    dealId: schedule.dealId,
                    dayOfWeek: schedule.dayOfWeek,
                    startMinute: schedule.startMinute,
                    endMinute: schedule.endMinute
                )
            )
        }

        return result
    }
}

private struct ScheduleKey: Hashable {
    let dayOfWeek: Int
    let startMinute: Int
    let endMinute: Int
}
