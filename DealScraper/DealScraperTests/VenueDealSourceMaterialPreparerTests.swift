//Created by Alex Skorulis on 19/6/2026.

import AppKit
import ASKCore
import CoreText
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct VenueDealSourceMaterialPreparerTests {

    @Test func preparePDFExtractsTextIntoMaterial() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let url = URL(string: "https://example.com/happy-hour.pdf")!
        let hash = URLNormalizer.hash(url)
        let pdfData = try Self.makePDFData(text: "Monday happy hour 4pm to 6pm")
        _ = try cache.store(data: pdfData, hash: hash, fileExtension: "pdf")

        let preparer = makePreparer(cache: cache)

        let material = try await preparer.preparePDF(at: url)

        #expect(material.type == .pdf)
        #expect(material.markdown == "Monday happy hour 4pm to 6pm")
        #expect(material.pngData == nil)
    }

    @Test func preparePDFThrowsWhenNoTextExtracted() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlPDFCache(directory: directory)
        let url = URL(string: "https://example.com/blank.pdf")!
        let hash = URLNormalizer.hash(url)
        let pdfData = try Self.makePDFData(text: "")
        _ = try cache.store(data: pdfData, hash: hash, fileExtension: "pdf")

        let preparer = makePreparer(cache: cache)

        await #expect(throws: VenueDealSourceMaterialPreparerError.missingPDFText) {
            try await preparer.preparePDF(at: url)
        }
    }

    private func makePreparer(cache: CrawlPDFCache) -> VenueDealSourceMaterialPreparer {
        VenueDealSourceMaterialPreparer(
            imageFetcher: CrawlImageFetcher(
                cache: CrawlImageCache(directory: FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString, isDirectory: true))
            ),
            webPageLoader: WebPageLoader(
                contentBlockGrouper: ContentBlockGrouper(),
                pageLinkExtractor: PageLinkExtractor(),
                webMarkdownGenerator: WebMarkdownGenerator()
            ),
            pdfFetcher: CrawlPDFFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlPDFFetcherError.invalidResponse
                }
            ),
            pdfTextExtractor: PDFTextExtractor()
        )
    }

    private static func makePDFData(text: String) throws -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw NSError(domain: "VenueDealSourceMaterialPreparerTests", code: 1)
        }

        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "VenueDealSourceMaterialPreparerTests", code: 2)
        }

        context.beginPDFPage(nil)

        if !text.isEmpty {
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
        }

        context.endPDFPage()
        context.closePDF()

        return data as Data
    }
}
