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
}
