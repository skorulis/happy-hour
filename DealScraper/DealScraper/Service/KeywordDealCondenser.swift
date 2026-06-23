//Created by Alex Skorulis on 23/6/2026.

import Foundation

struct KeywordDealCondenser: DealCondenser {

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

    func shouldMerge(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> Bool {
        guard hasSameDays(lhs, rhs) else { return false }

        let lhsKeywords = productKeywords(in: lhs)
        let rhsKeywords = productKeywords(in: rhs)
        guard !lhsKeywords.isEmpty, !rhsKeywords.isEmpty else { return false }
        return !lhsKeywords.intersection(rhsKeywords).isEmpty
    }

    private func combine(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> DealWithSchedules {
        let preferred: DealWithSchedules
        let other: DealWithSchedules
        if textLength(lhs) >= textLength(rhs) {
            preferred = lhs
            other = rhs
        } else {
            preferred = rhs
            other = lhs
        }

        let preferredDeal = preferred.deal
        let otherDeal = other.deal
        let deal = Deal(
            id: preferredDeal.id,
            venueId: preferredDeal.venueId,
            title: preferredDeal.title,
            creativeURL: preferredDeal.creativeURL ?? otherDeal.creativeURL,
            sourceURL: preferredDeal.sourceURL,
            details: preferredDeal.details,
            conditions: preferredDeal.conditions,
            status: preferredDeal.status
        )

        return DealWithSchedules(
            deal: deal,
            schedules: mergedSchedules(preferred.schedules, other.schedules)
        )
    }

    private func productKeywords(in item: DealWithSchedules) -> Set<String> {
        let text = dealText(item).lowercased()
        return Set(FilterKeywords.productKeywords.filter { text.contains($0) })
    }

    private func dealText(_ item: DealWithSchedules) -> String {
        [item.deal.title, item.deal.details, item.deal.conditions]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func textLength(_ item: DealWithSchedules) -> Int {
        dealText(item).count
    }

    private func hasSameDays(_ lhs: DealWithSchedules, _ rhs: DealWithSchedules) -> Bool {
        Set(lhs.schedules.map(\.dayOfWeek)) == Set(rhs.schedules.map(\.dayOfWeek))
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
            result.append(schedule)
        }

        return result
    }
}

private struct ScheduleKey: Hashable {
    let dayOfWeek: Int
    let startMinute: Int
    let endMinute: Int
}
