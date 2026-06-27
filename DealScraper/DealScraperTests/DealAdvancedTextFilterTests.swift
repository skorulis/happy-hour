//Created by Alex Skorulis on 18/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct DealAdvancedTextFilterTests {

    private let filter = DealAdvancedTextFilter()

    @Test func completeTextJoinsTextLines() {
        let textPieces = DealSourceTextPieces.textLines([
            "Happy Hour Mon–Fri 4–6pm",
            "$8 house wines",
        ])
        let text = DealAdvancedTextFilter.completeText(from: textPieces)
        #expect(text == "Happy Hour Mon–Fri 4–6pm\n$8 house wines")
    }

    @Test func completeTextJoinsContentBlocksWithFullText() {
        let blocks = [
            ContentBlock(title: "Wednesday Happy Hour", text: "$8 schooners", links: []),
            ContentBlock(title: nil, text: "Live music Fridays", links: []),
        ]
        let textPieces = DealSourceTextPieces.contentBlocks(blocks)
        let text = DealAdvancedTextFilter.completeText(from: textPieces)
        #expect(text == "Wednesday Happy Hour\n$8 schooners\n\nLive music Fridays")
    }

    @Test func filterPassesSourcesWithoutTextPieces() async {
        let pdfURL = URL(string: "https://pub.example.com/menu.pdf")!
        let pageURL = URL(string: "https://pub.example.com/specials")!
        let source = DiscoveredSource(
            url: pdfURL,
            sourceURL: pageURL,
            type: .pdf
        )
        let sources = [pdfURL: source]

        let result = await filter.filter(sources: sources)

        #expect(result.count == 1)
        #expect(result[pdfURL] == source)
    }

    @Test func acceptsSpecificRecurringDeal() async throws {
        let result = try await filter.describesSpecificDeals(text: "Wednesday happy hour")
        #expect(result)
    }

    @Test func rejectsGenericDealAvailabilityText() async throws {
        let text = "Our Monday to Friday meal deals are only available in our public bar, beer garden and Nude with bar service"
        let result = try await filter.describesSpecificDeals(text: text)
        #expect(!result)
    }

    @Test func rejectsStandardMenuWithServiceChargeFooter() async throws {
        let text = [
            "DESSERT AND CHEESE",
            "Rhubarb Soufflé $14",
            "Quince Trifle $15",
            "Profiterole $14",
            "Valrhona Chocolate Cake $15",
            "DD Ice Cream Sundae $15",
            "Scoops $5",
            "Dark Chocolate Truffle $5",
            "Cheese Selection 1 piece $12 / 3 pieces $30 / 5 pieces $45",
            "Groups of 8 or more will incur a 10% service charge (Monday to Saturday).",
            "A surcharge of 10% will apply on Sundays and 15% on public holidays.",
            "Credit and debit cards incur a surcharge of 1.5%.",
        ].joined(separator: "\n")

        let result = try await filter.describesSpecificDeals(text: text)
        #expect(!result)
    }

    @Test func acceptsDealWithSurchargeFooter() async throws {
        let text = [
            "HAPPY HOUR MON–FRI 4–6PM",
            "$8 schooners",
            "10% surcharge applies Sundays",
        ].joined(separator: "\n")

        let result = try await filter.describesSpecificDeals(text: text)
        #expect(result)
    }

    @Test func acceptsPosterStyleDealText() async throws {
        let text = [
            "HAPPY HOUR AT Hive Bar",
            "$8 SCHOONERS OF RECKLESS",
            "PALE ALE & LAGER",
            "$8 WINES, S10 GIN & TONICS",
            "$15 HOUSE SPRITZERS",
            "TUES - THURS 4PM - 6PM / FRI 3PM - 5PM",
        ].joined(separator: "\n")

        let result = try await filter.describesSpecificDeals(text: text)
        #expect(result)
    }
}
