//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionProvider: String, CaseIterable, Sendable {
    case openAI = "OpenAI"
    case openRouter = "OpenRouter"
}

enum VenueDealInstructions {

    static let multiSourceExtraction = """
        You extract deals from pub and restaurant promotional material for a single venue.

        Critical rule: never rewrite text. Every title, detail, condition, day, and time value must be copied character-for-character as shown in the sources. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.

        You receive multiple labeled sources (Source 1, Source 2, …) for the same venue. Image sources are attached either as embedded image data or as image URLs — use whichever form is provided. Webpage sources are provided as URLs — visit or read those pages to extract deal information.

        Rules:
        - Merge across sources: if the same promotion appears in multiple sources, return one deal (not duplicates).
        - Return one deal per distinct schedule (same days AND times).
        - title: the promotion headline as shown in the source material.
        - details: supporting text for this deal (prices, items, descriptions). One source line per entry.
        - conditions: exclusions, footnotes, terms, or qualifiers such as "dine-in only" or "members only". One source line per entry.
        - days: text that mentions which days apply, copied as written, e.g. 'EVERY TUES' or 'MON - FRI'.
        - times: text that mentions when the deal applies, copied as written, e.g. '4PM - 6PM'. If no time is mentioned, set times to exactly ['all day'].
        - sourceIndices: the 1-based source numbers where this deal appears, e.g. [1] or [1, 3].
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
        - If sources conflict, prefer the most complete information and note the conflict in conditions.
        - Large text is typically the deal title; smaller text is typically supporting details, times, or footers.
        """

    nonisolated static func promptPreamble(
        venueName: String,
        materials: [VenueDealSourceMaterial]
    ) -> String {
        var lines = [
            "Venue: \(venueName)",
            "",
            "Sources:",
        ]

        for material in materials {
            let typeLabel = material.type == .image ? "image" : "webpage link"
            lines.append(
                "Source \(material.index) (\(typeLabel)): \(material.url.absoluteString) (found on \(material.sourceURL.absoluteString))"
            )
        }

        lines.append("")
        lines.append("Extract all deals from the attached image data, image URLs, and webpage links listed above.")
        return lines.joined(separator: "\n")
    }
}
