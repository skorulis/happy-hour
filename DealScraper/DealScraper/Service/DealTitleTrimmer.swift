//Created by Alex Skorulis on 10/7/2026.

import Foundation

nonisolated enum DealTitleTrimmer {

  static func trimUntilStable(_ title: String) -> String {
    var result = title
    while true {
      let trimmed = trimOnce(result)
      if trimmed == result { return trimmed }
      result = trimmed
    }
  }

  static func trimOnce(_ title: String) -> String {
    var result = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !result.isEmpty else { return result }

    result = result.cleanLine()
    result = stripDayWord(from: result, atStart: true)
    result = stripDayWord(from: result, atStart: false)

    let time = #"(?:\d{1,2}(?:[:.]\d{2})?\s*(?:am|pm)?|\d{3,4}\s*(?:am|pm))"#

    let availableFromPattern = #"(?i)\s+available\s+from\s+(\#(time))\s*$"#
    if let stripped = stripSuffix(matching: availableFromPattern, in: result, timeCaptureGroups: [1]) {
      result = stripped
    }

    let fullRangePattern =
      #"(?i)\s+(\#(time))\s*(?:-|–|—|to|til|till|'til|until)\s*(\#(time))\s*$"#
    if let stripped = stripSuffix(matching: fullRangePattern, in: result, timeCaptureGroups: [1, 2]) {
      result = stripped
    }

    let partialRangePattern = #"(?i)\s+(\#(time))\s*(?:-|–|—)\s*$"#
    if let stripped = stripSuffix(matching: partialRangePattern, in: result, timeCaptureGroups: [1]) {
      result = stripped
    }

    let trailingTimePattern = #"(?i)\s+(\#(time))\s*$"#
    if let stripped = stripSuffix(matching: trailingTimePattern, in: result, timeCaptureGroups: [1]) {
      result = stripped
    }

    result = stripTrailingFromWord(from: result)
    result = stripTrailingEveryWord(from: result)
    result = stripTrailingOrphanSeparator(from: result)

    return result
  }

  private static func stripDayWord(from title: String, atStart: Bool) -> String {
    let parts = title.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    guard !parts.isEmpty else { return title }

    if atStart {
      if parts.count > 1,
        DealDay.parse(parts[0]) != nil,
        parts[1] == ":"
      {
        return parts.dropFirst(2).joined(separator: " ")
      }

      let first = parts[0]
      if first.hasSuffix(":"), DealDay.parse(String(first.dropLast())) != nil {
        return parts.dropFirst().joined(separator: " ")
      }

      guard DealDay.parse(first) != nil else { return title }
      return parts.dropFirst().joined(separator: " ")
    }

    guard parts.count > 1, DealDay.parse(parts[parts.count - 1]) != nil else { return title }
    return parts.dropLast().joined(separator: " ")
  }

  private static func stripTrailingFromWord(from title: String) -> String {
    let parts = title.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    guard parts.count > 1, parts.last?.caseInsensitiveCompare("from") == .orderedSame else {
      return title
    }
    return parts.dropLast().joined(separator: " ")
  }

  private static func stripTrailingEveryWord(from title: String) -> String {
    let parts = title.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    guard parts.count > 1, parts.last?.caseInsensitiveCompare("every") == .orderedSame else {
      return title
    }
    return parts.dropLast().joined(separator: " ")
  }

  private static func stripTrailingOrphanSeparator(from title: String) -> String {
    let pattern = #"\s*(?:-|–|—)\s*$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
      let matchRange = Range(match.range, in: title)
    else {
      return title
    }

    return String(title[..<matchRange.lowerBound])
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func stripSuffix(
    matching pattern: String,
    in text: String,
    timeCaptureGroups: [Int]
  ) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let matchRange = Range(match.range, in: text)
    else {
      return nil
    }

    for group in timeCaptureGroups {
      guard let timeRange = Range(match.range(at: group), in: text) else { return nil }
      let timeText = String(text[timeRange])
      guard DealHours.toMinutes(string: timeText) != nil else { return nil }
    }

    return String(text[..<matchRange.lowerBound])
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
