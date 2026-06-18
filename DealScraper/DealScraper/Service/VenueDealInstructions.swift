//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionProvider: String, CaseIterable, Sendable {
    case openAI = "OpenAI"
    case openRouter = "OpenRouter"
}

nonisolated enum VenueDealInstructions {

    static let introduction = """
        You extract deals from pub and restaurant promotional material for a single venue.
        """

    static let verbatimRule = """
        Critical rule: never rewrite text. Every title, detail, condition, day, and time value must be copied character-for-character as shown in the source. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.
        """

    static let fieldRules = """
        Rules:
        - Return one deal per distinct schedule (same days AND times).
        - title: the promotion headline as shown in the source material.
        - details: supporting text for this deal (prices, items, descriptions). One source line per entry.
        - conditions: exclusions, footnotes, terms, or qualifiers such as "dine-in only" or "members only". One source line per entry.
        - days: text that mentions which days apply, copied as written, e.g. 'EVERY TUES' or 'MON - FRI'.
        - times: text that mentions when the deal applies, copied as written, e.g. '4PM - 6PM'. If no time is mentioned, set times to exactly ['all day'].
        - Do not split a single promotion into multiple deals.
        - Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
        - Large text is typically the deal title; smaller text is typically supporting details, times, or footers.
        """

    static let imageSourceContext = """
        You receive one promotional image for the venue. The image is attached either as embedded image data or as an image URL — use whichever form is provided.
        """

    static let webpageSourceContext = """
        You receive a webpage URL for the venue. Only inspect the visible text on that page. Do not navigate to other pages or follow links. Ignore any images on the page.
        """

    static let imageExtractionTask = "Extract all deals from the attached image."

    static let webpageExtractionTask = "Extract all deals from the visible text on this webpage."

    nonisolated static func dealExtraction(for type: DealSourceType) -> String {
        let sourceContext: String
        switch type {
        case .image:
            sourceContext = imageSourceContext
        case .webpage, .pdf:
            sourceContext = webpageSourceContext
        }

        return """
        \(introduction)

        \(verbatimRule)

        \(sourceContext)

        \(fieldRules)
        """
    }

    nonisolated static func promptPreamble(
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        let typeLabel = material.type == .image ? "image" : "webpage link"
        let extractionTask = material.type == .image ? imageExtractionTask : webpageExtractionTask
        return """
        Venue: \(venueName)

        Source \(material.index) (\(typeLabel)): \(material.url.absoluteString) (found on \(material.sourceURL.absoluteString))

        \(extractionTask)
        """
    }
}
