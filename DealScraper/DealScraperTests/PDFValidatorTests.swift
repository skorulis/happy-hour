//Created by Alex Skorulis on 19/6/2026.

import ASKCore
import CoreGraphics
import CoreText
import Foundation
import PDFKit
import Testing
@testable import DealScraper

struct CrawlPDFCacheTests {

    @Test func storeAndFindCachedFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)

        let data = Data("pdf-bytes".utf8)
        let stored = try cache.store(data: data, hash: "abc123", fileExtension: "pdf")

        #expect(stored.lastPathComponent == "abc123.pdf")
        #expect(try Data(contentsOf: stored) == data)

        let found = try #require(cache.findCachedFileURL(for: "abc123"))
        #expect(found == stored)
    }
}

@MainActor
struct CrawlPDFFetcherTests {

    @Test func usesCacheWithoutDownloading() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let cachedData = Data("cached-pdf".utf8)
        _ = try cache.store(data: cachedData, hash: "cached-hash", fileExtension: "pdf")

        let fetcher = CrawlPDFFetcher(
            cache: cache,
            urlSession: FakeURLSession { _ in
                Issue.record("Should not download when cache exists")
                throw CrawlPDFFetcherError.invalidResponse
            }
        )

        let localURL = try await fetcher.localFileURL(
            for: URL(string: "https://example.com/menu.pdf")!,
            hash: "cached-hash"
        )

        #expect(try Data(contentsOf: localURL) == cachedData)
    }

    @Test func downloadsAndCachesOnMiss() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let remoteData = Data("downloaded-pdf".utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/menu.pdf")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/pdf"]
        )!

        let fetcher = CrawlPDFFetcher(
            cache: cache,
            urlSession: FakeURLSession(data: remoteData, response: response)
        )

        let localURL = try await fetcher.localFileURL(
            for: URL(string: "https://example.com/menu.pdf")!,
            hash: "download-hash"
        )

        #expect(try Data(contentsOf: localURL) == remoteData)
        #expect(cache.findCachedFileURL(for: "download-hash") == localURL)
    }
}

struct PDFValidatorYearFilterTests {

    @Test func filtersOutYearsBeforeCurrent() {
        let urls = [
            URL(string: "https://example.com/menus/happy-hour-2024.pdf")!,
            URL(string: "https://example.com/menus/happy-hour-2026.pdf")!,
        ]

        let filtered = PDFVersionFilter.filterToLatestVersions(urls, currentYear: 2026)

        #expect(filtered.count == 1)
        #expect(filtered[0].lastPathComponent == "happy-hour-2026.pdf")
    }

    @Test func keepsUnversionedURLs() {
        let urls = [
            URL(string: "https://example.com/files/menu.pdf")!,
            URL(string: "https://example.com/files/menu-2026.pdf")!,
        ]

        let filtered = PDFVersionFilter.filterToLatestVersions(urls, currentYear: 2026)

        #expect(filtered.count == 2)
    }

    @Test func filtersOldYearsIndependently() {
        let urls = [
            URL(string: "https://example.com/drinks-2024.pdf")!,
            URL(string: "https://example.com/events-2026.pdf")!,
        ]

        let filtered = PDFVersionFilter.filterToLatestVersions(urls, currentYear: 2026)

        #expect(filtered.count == 1)
        #expect(filtered[0].lastPathComponent == "events-2026.pdf")
    }

    @Test func keepsAllWhenNoYearsPresent() {
        let urls = [
            URL(string: "https://example.com/happy-hour.pdf")!,
            URL(string: "https://example.com/specials.pdf")!,
        ]

        let filtered = PDFVersionFilter.filterToLatestVersions(urls, currentYear: 2026)

        #expect(filtered.count == 2)
    }
}

@MainActor
struct PDFValidatorTests {

    @Test func acceptsPDFWithDealKeywords() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let hash = "happy-hour-hash"
        let pdfData = try Self.makePDFData(text: "Monday to Friday happy hour specials from 4pm")
        _ = try cache.store(data: pdfData, hash: hash, fileExtension: "pdf")

        let validator = PDFValidator(
            fetcher: CrawlPDFFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlPDFFetcherError.invalidResponse
                }
            ),
            textExtractor: PDFTextExtractor()
        )

        let result = await validator.validatePDF(
            url: URL(string: "https://example.com/happy-hour.pdf")!,
            hash: hash
        )

        #expect(result != nil)
    }

    @Test func rejectsPDFWithoutDealKeywords() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let hash = "about-hash"
        let pdfData = try Self.makePDFData(text: "About our venue and private dining rooms")
        _ = try cache.store(data: pdfData, hash: hash, fileExtension: "pdf")

        let validator = PDFValidator(
            fetcher: CrawlPDFFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlPDFFetcherError.invalidResponse
                }
            ),
            textExtractor: PDFTextExtractor()
        )

        let result = await validator.validatePDF(
            url: URL(string: "https://example.com/about.pdf")!,
            hash: hash
        )

        #expect(result == nil)
    }

    @Test func validatePDFsAppliesYearDedup() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let pdfData = try Self.makePDFData(text: "Weekly happy hour menu")
        let url2024 = URL(string: "https://example.com/menu-2024.pdf")!
        let url2026 = URL(string: "https://example.com/menu-2026.pdf")!
        _ = try cache.store(data: pdfData, hash: URLNormalizer.hash(url2024), fileExtension: "pdf")
        _ = try cache.store(data: pdfData, hash: URLNormalizer.hash(url2026), fileExtension: "pdf")

        let validator = PDFValidator(
            fetcher: CrawlPDFFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlPDFFetcherError.invalidResponse
                }
            ),
            textExtractor: PDFTextExtractor()
        )

        let results = await validator.validatePDFs(urls: [url2024, url2026])

        #expect(results.count == 1)
        #expect(results[0].url.lastPathComponent == "menu-2026.pdf")
    }

    private static func makePDFData(text: String) throws -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw NSError(domain: "PDFValidatorTests", code: 1)
        }

        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PDFValidatorTests", code: 2)
        }

        context.beginPDFPage(nil)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1, y: -1)

        let font = CTFontCreateWithName("Helvetica" as CFString, 14, nil)
        let attributed = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: 72, y: 72)
        CTLineDraw(line, context)

        context.endPDFPage()
        context.closePDF()

        return data as Data
    }
}
