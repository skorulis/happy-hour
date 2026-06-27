//Created by Alex Skorulis on 18/6/2026.

import Foundation
import FoundationModels

@Generable
struct DealTextClassification {
    @Guide(description: "True if the text describes one or more promotional food or drink deals — discounted prices, named specials, happy hours, or recurring day-specific deals. False for standard menus at regular prices, operational policy text (service charges, surcharges, card fees, opening hours), or generic mentions that deals exist without naming a specific offering.")
    var describesSpecificDeals: Bool
}

// TODO: This isn't very accurate
struct DealAdvancedTextFilter {

    enum Error: Swift.Error {
        case modelUnavailable
        case emptyInput
    }

    func describesSpecificDeals(text: String) async throws -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Error.emptyInput
        }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw Error.modelUnavailable
        }

        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let response = try await session.respond(
            to: Self.makePrompt(from: trimmed),
            generating: DealTextClassification.self
        )
        return response.content.describesSpecificDeals
    }

    func filter(sources: [URL: DiscoveredSource]) async -> [URL: DiscoveredSource] {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            print("CRAWL: DealAdvancedTextFilter skipped — model unavailable")
            return sources
        }

        var filtered: [URL: DiscoveredSource] = [:]

        for (url, source) in sources {
            guard let textPieces = source.textPieces else {
                filtered[url] = source
                continue
            }

            let text = Self.completeText(from: textPieces)
            guard !text.isEmpty else {
                filtered[url] = source
                continue
            }

            do {
                if try await describesSpecificDeals(text: text) {
                    filtered[url] = source
                } else {
                    print("CRAWL: Dropped source \(url) — text does not describe specific deals")
                }
            } catch DealAdvancedTextFilter.Error.modelUnavailable {
                print("CRAWL: Keeping source \(url) — deal classifier unavailable")
                filtered[url] = source
            } catch {
                print("CRAWL: Dropped source \(url) — classification failed: \(error)")
            }
        }

        return filtered
    }

    static func completeText(from textPieces: DealSourceTextPieces) -> String {
        switch textPieces {
        case let .textLines(lines):
            return lines.joined(separator: "\n")
        case let .contentBlocks(blocks):
            return blocks.map(\.fullText).joined(separator: "\n\n")
        }
    }

    private static let instructions = """
        You classify pub and restaurant text to decide whether it describes promotional food or drink deals.

        Return describesSpecificDeals = true when the text names one or more promotional offerings, such as:
        - A named recurring promotion: "Wednesday happy hour", "Monday steak night $25"
        - Discounted or time-bound offers: "$8 schooners 4–6pm Mon–Fri"
        - A specials board listing day-specific deals with prices or times

        Return describesSpecificDeals = false when the text is:
        - A standard menu section listing items at regular prices with no special or promo language
        - Operational or policy text mentioning days: service charges, surcharges, public holiday loading, card fees, group booking charges, opening hours
        - Generic deal availability without naming a specific offering
        - A pointer to deals elsewhere: "See our specials page", "We have great deals"

        Days of the week in service charge or surcharge footers do not make text promotional.

        Examples:
        - "Wednesday happy hour" → true (names a specific recurring deal)
        - "HAPPY HOUR MON–FRI 4–6PM\\n$8 schooners\\n10% surcharge applies Sundays" → true (named promotion with schedule and prices; ignore surcharge footer)
        - "DESSERT AND CHEESE\\nRhubarb Soufflé $14\\nValrhona Chocolate Cake $15\\nGroups of 8 or more will incur a 10% service charge (Monday to Saturday). A surcharge of 10% will apply on Sundays" → false (standard menu; days refer to surcharges, not specials)
        - "Our Monday to Friday meal deals are only available in our public bar, beer garden and Nude with bar service" → false (describes deal availability and location, not a specific offering)
        - "Monday to Saturday: 9am - 6am" → false (opening hours)
        - "See our specials page" → false
        - "We have great deals" → false

        Multiple distinct deals in one text is fine — return true if any promotional offerings are described.
        """

    private static func makePrompt(from text: String) -> String {
        """
        Does the following text describe one or more promotional food or drink deals?

        \(text)
        """
    }
}
