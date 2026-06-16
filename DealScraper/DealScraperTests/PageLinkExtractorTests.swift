//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct PageLinkExtractorTests {

    private let extractor = PageLinkExtractor()
    private let pageURL = URL(string: "https://www.thestrawbs.com.au/")!

    @Test func extractsVisibleLinkText() throws {
        let html = """
        <html>
        <body>
          <a href="/bookings">Book now</a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].text == "Book now")
        #expect(links[0].url.absoluteString == "https://www.thestrawbs.com.au/bookings")
    }

    @Test func usesTitleAttributeWhenNoVisibleText() throws {
        let html = """
        <html>
        <body>
          <a href="/menu" title="View our menu"></a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].text == "View our menu")
        #expect(links[0].url.absoluteString == "https://www.thestrawbs.com.au/menu")
    }

    @Test func fallsBackToHrefWhenNoTextOrTitle() throws {
        let html = """
        <html>
        <body>
          <a href="/menu"></a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].text == "/menu")
        #expect(links[0].url.absoluteString == "https://www.thestrawbs.com.au/menu")
    }

    @Test func resolvesRelativeURLs() throws {
        let html = """
        <html>
        <body>
          <a href="/specials">Specials</a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].url.absoluteString == "https://www.thestrawbs.com.au/specials")
    }

    @Test func includesNavAndFooterLinks() throws {
        let html = """
        <html>
        <body>
          <nav><a href="/menu">Menu</a></nav>
          <main><a href="/bookings">Book</a></main>
          <footer><a href="/contact">Contact</a></footer>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)
        let texts = links.compactMap(\.text)

        #expect(texts.contains("Menu"))
        #expect(texts.contains("Book"))
        #expect(texts.contains("Contact"))
        #expect(links.count == 3)
    }

    @Test func deduplicatesByURL() throws {
        let html = """
        <html>
        <body>
          <a href="/menu">Menu</a>
          <a href="/menu">Menu again</a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].text == "Menu")
    }

    @Test func skipsNonHttpLinks() throws {
        let html = """
        <html>
        <body>
          <a href="mailto:hello@example.com">Email</a>
          <a href="javascript:void(0)">Click</a>
          <a href="#section">Section</a>
          <a href="/valid">Valid</a>
        </body>
        </html>
        """

        let links = try extractor.extract(html: html, pageURL: pageURL)

        #expect(links.count == 1)
        #expect(links[0].text == "Valid")
        #expect(links[0].url.absoluteString == "https://www.thestrawbs.com.au/valid")
    }
}
