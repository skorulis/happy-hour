//Created by Alex Skorulis on 23/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct CanonicalURLExtractorTests {

    private let extractor = CanonicalURLExtractor()
    private let baseURL = URL(string: "https://www.goldenbarleyhotel.com.au/")!

    @Test func extractsAbsoluteCanonicalURL() throws {
        let html = """
        <html>
        <head>
          <link rel="canonical" href="https://www.goldenbarleyhotel.com.au/home">
        </head>
        <body></body>
        </html>
        """

        let canonical = try extractor.extract(html: html, pageURL: baseURL)

        #expect(canonical?.absoluteString == "https://www.goldenbarleyhotel.com.au/home")
    }

    @Test func resolvesRelativeCanonicalURL() throws {
        let html = """
        <html>
        <head>
          <link rel="canonical" href="/home">
        </head>
        <body></body>
        </html>
        """

        let canonical = try extractor.extract(html: html, pageURL: baseURL)

        #expect(canonical?.absoluteString == "https://www.goldenbarleyhotel.com.au/home")
    }

    @Test func acceptsCanonicalInCompoundRelAttribute() throws {
        let html = """
        <html>
        <head>
          <link rel="canonical alternate" href="/home">
        </head>
        <body></body>
        </html>
        """

        let canonical = try extractor.extract(html: html, pageURL: baseURL)

        #expect(canonical?.absoluteString == "https://www.goldenbarleyhotel.com.au/home")
    }

    @Test func returnsNilWhenCanonicalMissing() throws {
        let html = """
        <html>
        <head></head>
        <body></body>
        </html>
        """

        let canonical = try extractor.extract(html: html, pageURL: baseURL)

        #expect(canonical == nil)
    }

    @Test func ignoresCrossOriginCanonical() throws {
        let html = """
        <html>
        <head>
          <link rel="canonical" href="https://example.com/home">
        </head>
        <body></body>
        </html>
        """

        let canonical = try extractor.extract(html: html, pageURL: baseURL)

        #expect(canonical == nil)
    }

    @Test func rootAndHomePagesResolveToSameCanonicalURL() throws {
        let html = """
        <html>
        <head>
          <link rel="canonical" href="https://www.goldenbarleyhotel.com.au/home">
        </head>
        <body></body>
        </html>
        """

        let rootPageURL = URL(string: "https://www.goldenbarleyhotel.com.au/")!
        let homePageURL = URL(string: "https://www.goldenbarleyhotel.com.au/home")!

        let fromRoot = try extractor.extract(html: html, pageURL: rootPageURL)
        let fromHome = try extractor.extract(html: html, pageURL: homePageURL)

        #expect(fromRoot == fromHome)
        #expect(fromRoot?.absoluteString == "https://www.goldenbarleyhotel.com.au/home")
    }
}
