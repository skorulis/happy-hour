//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionProvider: String, CaseIterable, Sendable {
    case openAI = "OpenAI"
    case openRouter = "OpenRouter"
}

enum VenueDealInstructions {

    static let dealExtraction = """
        You extract deals from pub and restaurant promotional material for a single venue.

        Critical rule: never rewrite text. Every title, detail, condition, day, and time value must be copied character-for-character as shown in the source. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.

        You receive one promotional image for the venue. The image is attached either as embedded image data or as an image URL — use whichever form is provided.

        Rules:
        - Return one deal per distinct schedule (same days AND times).
        - title: the promotion headline as shown in the source material.
        - details: supporting text for this deal (prices, items, descriptions). One source line per entry.
        - conditions: exclusions, footnotes, terms, or qualifiers such as "dine-in only" or "members only". One source line per entry.
        - days: text that mentions which days apply, copied as written, e.g. 'EVERY TUES' or 'MON - FRI'.
        - times: text that mentions when the deal applies, copied as written, e.g. '4PM - 6PM'. If no time is mentioned, set times to exactly ['all day'].
        - sourceIndices: the 1-based source number from the preamble, as a single-element array, e.g. [1].
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
        - Large text is typically the deal title; smaller text is typically supporting details, times, or footers.
        """

    nonisolated static func promptPreamble(
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        let typeLabel = material.type == .image ? "image" : "webpage link"
        return """
        Venue: \(venueName)

        Source \(material.index) (\(typeLabel)): \(material.url.absoluteString) (found on \(material.sourceURL.absoluteString))

        Extract all deals from the attached image.
        """
    }
}
