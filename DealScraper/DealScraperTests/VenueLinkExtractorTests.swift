//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueLinkExtractorTests {

    private let extractor = VenueLinkExtractor()

    @Test func extractsWhatsOnLink() throws {
        let html = """
        <html>
        <body>
          <a href="/whats-on">What's On</a>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.whatsOn?.absoluteString == "https://pub.example.com/whats-on")
        #expect(result.instagram == nil)
        #expect(result.facebook == nil)
    }

    @Test func extractsSocialLinksFromFooter() throws {
        let html = """
        <html>
        <body>
          <footer>
            <a href="https://www.instagram.com/theroyalpub/">Instagram</a>
            <a href="https://facebook.com/theroyalpub">Facebook</a>
          </footer>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.instagram?.absoluteString == "https://www.instagram.com/theroyalpub")
        #expect(result.facebook?.absoluteString == "https://facebook.com/theroyalpub")
        #expect(result.whatsOn == nil)
    }

    @Test func ignoresExternalLinksForWhatsOn() throws {
        let html = """
        <html>
        <body>
          <a href="https://other.example.com/events">Events</a>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.whatsOn == nil)
    }

    @Test func returnsFirstMatchForEachLinkType() throws {
        let html = """
        <html>
        <body>
          <a href="/events">Events</a>
          <a href="/specials">Specials</a>
          <a href="https://instagram.com/first">Instagram 1</a>
          <a href="https://instagram.com/second">Instagram 2</a>
          <a href="https://facebook.com/first">Facebook 1</a>
          <a href="https://fb.com/second">Facebook 2</a>
        </body>
        </html>
        """
        let baseURL = URL(string: "https://pub.example.com")!
        let pageURL = URL(string: "https://pub.example.com/")!

        let result = try extractor.extract(html: html, pageURL: pageURL, baseURL: baseURL)

        #expect(result.whatsOn?.absoluteString == "https://pub.example.com/events")
        #expect(result.instagram?.absoluteString == "https://instagram.com/first")
        #expect(result.facebook?.absoluteString == "https://facebook.com/first")
    }
}
