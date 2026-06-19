//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionProvider: String, CaseIterable, Sendable {
    case openRouter = "OpenRouter"
    case openAI = "OpenAI"
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
        - title: the promotion headline as shown in the source material. Do not use generic phrases that do not describe what the deal is.
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

    static let markdownSourceContext = """
        You receive markdown converted from a venue webpage. Only use the visible promotional text in the markdown. Do not invent content. Ignore navigation, footers, and images.
        """

    static let pdfSourceContext = """
        You receive promotional text extracted from a venue PDF document. Only use the visible promotional text provided. Do not invent content. Ignore headers, footers, and page numbers.
        """

    static let imageExtractionTask = "Extract all deals from the attached image."

    static let webpageExtractionTask = "Extract all deals from the visible text on this webpage."

    static let markdownExtractionTask = "Extract all deals from the webpage markdown below."

    static let pdfExtractionTask = "Extract all deals from the PDF text below. Ignore standard pricing"

    nonisolated static func dealExtraction(for type: DealSourceType) -> String {
        let sourceContext: String
        switch type {
        case .image:
            sourceContext = imageSourceContext
        case .webpage:
            sourceContext = webpageSourceContext
        case .pdf:
            sourceContext = pdfSourceContext
        }

        return """
        \(introduction)

        \(verbatimRule)

        \(sourceContext)

        \(fieldRules)
        """
    }

    nonisolated static func dealExtraction(for material: VenueDealSourceMaterial) -> String {
        if material.type == .pdf {
            return """
            \(introduction)

            \(verbatimRule)

            \(pdfSourceContext)

            \(fieldRules)
            """
        }

        if material.markdown != nil {
            return """
            \(introduction)

            \(verbatimRule)

            \(markdownSourceContext)

            \(fieldRules)
            """
        }

        return dealExtraction(for: material.type)
    }

    nonisolated static func promptPreamble(
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        let typeLabel: String
        let extractionTask: String
        if material.type == .image {
            typeLabel = "image"
            extractionTask = imageExtractionTask
        } else if material.type == .pdf {
            typeLabel = "PDF text"
            extractionTask = pdfExtractionTask
        } else if material.markdown != nil {
            typeLabel = "webpage markdown"
            extractionTask = markdownExtractionTask
        } else {
            typeLabel = "webpage link"
            extractionTask = webpageExtractionTask
        }

        return """
        Venue: \(venueName)

        Source \(material.index) (\(typeLabel)): \(material.url.absoluteString) (found on \(material.sourceURL.absoluteString))

        \(extractionTask)
        """
    }
}
