//Created by Alex Skorulis on 23/6/2026.

import Foundation

nonisolated enum DealScheduleFormatting {
    /// Mon → Sun display order (calendar weekday values 2–7, 1).
    static let weekdaysInDisplayOrder = [2, 3, 4, 5, 6, 7, 1]

    private static var weekdayDisplayOrder: [Int] { weekdaysInDisplayOrder }

    static func formattedSummary(_ schedules: [DealSchedule]) -> String {
        guard !schedules.isEmpty else { return "" }

        var groups: [TimeRangeKey: Set<Int>] = [:]
        for schedule in schedules {
            let key = TimeRangeKey(start: schedule.startMinute, end: schedule.endMinute)
            groups[key, default: []].insert(schedule.dayOfWeek)
        }

        return groups
            .sorted { lhs, rhs in
                let lhsFirstDay = weekdayDisplayOrder.firstIndex(of: lhs.value.min(by: weekdaySort)!) ?? 0
                let rhsFirstDay = weekdayDisplayOrder.firstIndex(of: rhs.value.min(by: weekdaySort)!) ?? 0
                if lhsFirstDay != rhsFirstDay { return lhsFirstDay < rhsFirstDay }
                if lhs.key.start != rhs.key.start { return lhs.key.start < rhs.key.start }
                return lhs.key.end < rhs.key.end
            }
            .map { key, days in
                formatGroup(days: Array(days), start: key.start, end: key.end)
            }
            .joined(separator: ", ")
    }

    private struct TimeRangeKey: Hashable {
        let start: Int
        let end: Int
    }

    private static func formatGroup(days: [Int], start: Int, end: Int) -> String {
        let dayPart = formatDayRanges(days)
        if start == 0, end == 1_440 {
            return dayPart
        }
        return "\(dayPart) \(formattedMinute(start))–\(formattedMinute(end))"
    }

    private static func formatDayRanges(_ days: [Int]) -> String {
        let sorted = days.sorted(by: weekdaySort)
        var ranges: [String] = []
        var rangeStart = sorted[0]
        var rangeEnd = sorted[0]

        for day in sorted.dropFirst() {
            if areConsecutive(rangeEnd, day) {
                rangeEnd = day
            } else {
                ranges.append(formatDayRange(from: rangeStart, to: rangeEnd))
                rangeStart = day
                rangeEnd = day
            }
        }
        ranges.append(formatDayRange(from: rangeStart, to: rangeEnd))
        return ranges.joined(separator: ", ")
    }

    private static func areConsecutive(_ first: Int, _ second: Int) -> Bool {
        guard let firstIndex = weekdayDisplayOrder.firstIndex(of: first),
              let secondIndex = weekdayDisplayOrder.firstIndex(of: second)
        else {
            return false
        }
        return secondIndex == firstIndex + 1
    }

    private static func weekdaySort(_ lhs: Int, _ rhs: Int) -> Bool {
        let lhsIndex = weekdayDisplayOrder.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = weekdayDisplayOrder.firstIndex(of: rhs) ?? Int.max
        return lhsIndex < rhsIndex
    }

    private static func formatDayRange(from start: Int, to end: Int) -> String {
        if start == end {
            return dayName(for: start)
        }
        return "\(dayName(for: start))-\(dayName(for: end))"
    }

    static func dayName(for weekday: Int) -> String {
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "Day \(weekday)"
        }
    }

    private static func formattedMinute(_ minute: Int) -> String {
        let normalizedMinute = minutesWithinDay(minute)
        let hours = normalizedMinute / 60
        let minutes = normalizedMinute % 60
        return String(format: "%d:%02d", hours, minutes)
    }

    static func minutesWithinDay(_ minute: Int) -> Int {
        minute % 1_440
    }

    static func date(fromMinutes minutes: Int) -> Date {
        var components = DateComponents()
        // 24:00 is stored as 1440 minutes but DatePicker only represents midnight as 00:00.
        let normalizedMinutes = minutesWithinDay(minutes)
        components.hour = normalizedMinutes / 60
        components.minute = normalizedMinutes % 60
        return Calendar.current.date(from: components) ?? .now
    }

    static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// Converts a DatePicker value for an end time. Midnight (00:00) means end of day (24:00).
    static func endMinutes(from date: Date) -> Int {
        let minutes = minutes(from: date)
        return minutes == 0 ? 1_440 : minutes
    }

    static func endMinutes(from date: Date, startMinute: Int) -> Int {
        normalizedEndMinute(endMinute: endMinutes(from: date), startMinute: startMinute)
    }

    static func normalizedEndMinute(endMinute: Int, startMinute: Int) -> Int {
        if endMinute == 1_440 {
            return DealHours.adjustedEndMinute(start: startMinute, end: 0)
        }
        if endMinute > 1_440 {
            return DealHours.adjustedEndMinute(
                start: startMinute,
                end: minutesWithinDay(endMinute)
            )
        }
        return DealHours.adjustedEndMinute(start: startMinute, end: endMinute)
    }

    static func sortedSchedules(_ schedules: [DealSchedule]) -> [DealSchedule] {
        schedules.sorted { lhs, rhs in
            let lhsDay = weekdayDisplayOrder.firstIndex(of: lhs.dayOfWeek) ?? Int.max
            let rhsDay = weekdayDisplayOrder.firstIndex(of: rhs.dayOfWeek) ?? Int.max
            if lhsDay != rhsDay { return lhsDay < rhsDay }
            if lhs.startMinute != rhs.startMinute { return lhs.startMinute < rhs.startMinute }
            return lhs.endMinute < rhs.endMinute
        }
    }
}

extension DealWithSchedules {
    var formattedScheduleSummary: String {
        DealScheduleFormatting.formattedSummary(schedules)
    }
}
