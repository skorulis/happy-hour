//Created by Alex Skorulis on 18/6/2026.

import Foundation
import FoundationModels

@Generable
struct DealTextClassification {
    @Guide(description: "True if the text describes one or more specific food or drink deals/promotions. False if it only mentions that deals exist, refers to deal categories generically, or describes where/when deals are available without naming a specific offering.")
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
            } catch {
                print("CRAWL: Keeping source \(url) — classification failed: \(error)")
                filtered[url] = source
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
        You classify pub and restaurant text to decide whether it describes specific food or drink deals or promotions.

        Return describesSpecificDeals = true when the text names one or more specific offerings, such as a named promotion, menu items with prices, or a recurring deal with identifiable schedule.

        Return describesSpecificDeals = false when the text only mentions that deals exist, refers to deal categories generically, or describes where or when deals are available without naming a specific offering.

        Examples:
        - "Wednesday happy hour" → true (names a specific recurring deal)
        - "Our Monday to Friday meal deals are only available in our public bar, beer garden and Nude with bar service" → false (describes deal availability and location, not a specific offering)
        - "See our specials page" → false
        - "We have great deals" → false

        Multiple distinct deals in one text is fine — return true if any specific offerings are described.
        """

    private static func makePrompt(from text: String) -> String {
        """
        Does the following text describe one or more specific food or drink deals or promotions?

        \(text)
        """
    }
}
