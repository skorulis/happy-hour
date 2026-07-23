//Created by Alex Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct EmailExtractorTests {

    private let extractor = EmailExtractor()

    @Test func extractsPlainTextEmails() {
        let text = "Contact us at hello@example.com or bookings@venue.com.au for more info."

        #expect(extractor.extract(from: text) == [
            "hello@example.com",
            "bookings@venue.com.au",
        ])
    }

    @Test func stripsMailtoPrefix() {
        let html = #"<a href="mailto:Hello@Example.com">Email</a>"#

        #expect(extractor.extract(from: html) == ["hello@example.com"])
    }

    @Test func deduplicatesCaseInsensitively() {
        let text = "Hello@Example.com hello@example.com HELLO@EXAMPLE.COM"

        #expect(extractor.extract(from: text) == ["hello@example.com"])
    }

    @Test func returnsEmptySetWhenNoEmails() {
        let text = "No contact details on this page."

        #expect(extractor.extract(from: text).isEmpty)
    }

    @Test func ignoresRetinaImageFilenames() {
        let text = """
        <img src="apollo-bay-yha-700x507@2x.jpg">
        <img src="logo@3x.png">
        Contact hello@venue.com
        """

        #expect(extractor.extract(from: text) == ["hello@venue.com"])
    }

    @Test func ignoresWixSentryTelemetryEmails() {
        let text = """
        18d2f96d279149989b95faf0a4b41882@sentry-next.wixpress.com
        dd0a55ccb8124b9c9d938e3acf41f8aa@sentry.wixpress.com
        8c4075d5481d476e945486754f783364@sentry.io
        Contact hello@venue.com
        """

        #expect(extractor.extract(from: text) == ["hello@venue.com"])
    }
}
