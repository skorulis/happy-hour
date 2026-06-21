//Created by Alex Skorulis on 22/6/2026.

import AppKit
import CoreText
import Foundation
import PDFKit
import Testing
@testable import DealScraper

struct PDFMarkdownGeneratorTests {

    @Test func markdownFromMultiFontPageUsesHeading() throws {
        let page = try makePDFPage(title: "HAPPY HOUR", body: "Monday to Friday happy hour 4pm to 6pm")
        let generator = PDFMarkdownGenerator()

        let markdown = generator.markdown(from: page)

        #expect(markdown.contains("## HAPPY HOUR"))
        #expect(markdown.contains("Monday to Friday happy hour 4pm to 6pm"))
        #expect(markdown.range(of: "## HAPPY HOUR\n\nMonday") != nil)
    }

    @Test func markdownFromListLinesUsesBulletSyntax() throws {
        let page = try makePDFPage(
            title: "DRINKS",
            body: "• $5 house wines\n• $6 schooners"
        )
        let generator = PDFMarkdownGenerator()

        let markdown = generator.markdown(from: page)

        #expect(markdown.contains("- $5 house wines"))
        #expect(markdown.contains("- $6 schooners"))
    }

    private func makePDFPage(title: String, body: String) throws -> PDFPage {
        let pdfURL = try makePDFURL(title: title, body: body)
        guard let document = PDFDocument(url: pdfURL), let page = document.page(at: 0) else {
            throw NSError(domain: "PDFMarkdownGeneratorTests", code: 1)
        }
        return page
    }

    private func makePDFURL(title: String, body: String) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw NSError(domain: "PDFMarkdownGeneratorTests", code: 2)
        }

        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PDFMarkdownGeneratorTests", code: 3)
        }

        context.beginPDFPage(nil)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1, y: -1)

        try drawText(title, fontSize: 24, at: CGPoint(x: 72, y: 120), in: context)

        var y: CGFloat = 180
        for line in body.components(separatedBy: "\n") {
            try drawText(line, fontSize: 12, at: CGPoint(x: 72, y: y), in: context)
            y += 24
        }

        context.endPDFPage()
        context.closePDF()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        try (data as Data).write(to: url)
        return url
    }

    private func drawText(
        _ text: String,
        fontSize: CGFloat,
        at point: CGPoint,
        in context: CGContext
    ) throws {
        let fontName = fontSize >= 18 ? "Helvetica-Bold" : "Helvetica"
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributed = NSAttributedString(
            string: text,
            attributes: [.font: font]
        )
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = point
        CTLineDraw(line, context)
    }
}
