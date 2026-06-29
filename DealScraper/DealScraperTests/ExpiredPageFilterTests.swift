//Created by Alex Skorulis on 29/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct ExpiredPageFilterTests {

    @Test func detectsExpiredEventPage() {
        let html = """
        <html><body>
        <p>This event has passed.</p>
        <h1>$12 Happy Hour</h1>
        <p>From 5pm – 7pm daily.</p>
        </body></html>
        """
        #expect(DealTextFilter.isExpiredPage(html))
    }

    @Test func acceptsActiveEventPage() {
        let html = """
        <html><body>
        <h1>$12 Happy Hour</h1>
        <p>From 5pm – 7pm daily.</p>
        </body></html>
        """
        #expect(!DealTextFilter.isExpiredPage(html))
    }

    @Test func expiredPageHasNoDealContentBlocks() {
        let page = LoadedPage(
            url: URL(string: "https://example.com/event/margarita-hour")!,
            html: "<p>This event has passed.</p><h1>Happy Hour</h1><p>5pm - 7pm daily</p>",
            markdown: nil,
            imageURLs: [],
            contentBlocks: [
                ContentBlock(
                    title: "Happy Hour",
                    text: "5pm - 7pm daily",
                    links: []
                ),
            ],
            links: []
        )
        #expect(DealTextFilter.isExpiredPage(page.html))
        #expect(page.dealContentBlocks.isEmpty)
    }
}
