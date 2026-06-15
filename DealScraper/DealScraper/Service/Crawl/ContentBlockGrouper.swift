//Created by Alex Skorulis on 15/6/2026.

import Foundation
import SwiftSoup

struct ContentBlockGrouper {

    private static let boilerplateSelectors = [
        "script",
        "style",
        "noscript",
        "svg",
        "iframe",
        "template",
        "nav",
        "footer",
        "header",
        "[role=navigation]",
        "[role=contentinfo]",
        "[role=banner]",
        "#SITE_HEADER",
        "#SITE_FOOTER",
        "[data-hook=header]",
        "[data-hook=footer]",
    ]

    private static let mainContentSelectors = [
        "main",
        "[role=main]",
        "#PAGES_CONTAINER",
        "#SITE_PAGES",
        "article",
        "body",
    ]

    private static let pageMarkerTexts = [
        "top of page",
        "bottom of page",
    ]

    private enum Segment: Equatable {
        case heading(String)
        case text(String)
        case link(text: String, url: URL)
    }

    func group(html: String, pageURL: URL) throws -> [ContentBlock] {
        let wixGalleryBlocks = Self.extractWixGalleryBlocks(from: html)
        let document = try SwiftSoup.parse(html, pageURL.absoluteString)
        try removeBoilerplate(from: document)
        let root = try findMainContentRoot(in: document)
        let segments = try collectSegments(element: root, pageURL: pageURL)
        return enrichBlocks(buildBlocks(from: segments), with: wixGalleryBlocks)
    }

    // MARK: - Boilerplate removal

    private func removeBoilerplate(from document: Document) throws {
        for selector in Self.boilerplateSelectors {
            try document.select(selector).remove()
        }

        for element in try document.getAllElements() {
            let text = try element.ownText()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if Self.pageMarkerTexts.contains(text) {
                try element.remove()
            }
        }
    }

    // MARK: - Main content

    private func findMainContentRoot(in document: Document) throws -> Element {
        for selector in Self.mainContentSelectors {
            if let element = try document.select(selector).first() {
                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if text.count >= 50 {
                    return element
                }
            }
        }

        if let body = document.body() {
            return body
        }

        return document
    }

    // MARK: - Segment collection

    private func collectSegments(element: Element, pageURL: URL) throws -> [Segment] {
        let dataHook = (try? element.attr("data-hook")) ?? ""

        if dataHook == "item-description" {
            return []
        }

        if dataHook == "item-title" {
            return try itemTitleSegments(element: element)
        }

        if try isSemanticHeading(element) || isHeuristicHeading(element) {
            let title = try normalizedText(from: element.text())
            guard !title.isEmpty else { return [] }
            return [.heading(title)]
        }

        let tag = element.tagName().lowercased()
        if tag == "a" {
            return try linkSegment(from: element, pageURL: pageURL)
        }

        var segments: [Segment] = []
        for child in element.children() {
            segments.append(contentsOf: try collectSegments(element: child, pageURL: pageURL))
        }

        if element.children().isEmpty() {
            let text = try normalizedText(from: element.text())
            if !text.isEmpty {
                segments.append(.text(text))
            }
        }

        return segments
    }

    private func linkSegment(from element: Element, pageURL: URL) throws -> [Segment] {
        let href = try element.attr("href")
        guard let url = URLNormalizer.resolve(href, relativeTo: pageURL) else { return [] }

        let text = try normalizedText(from: element.text())
        let label = text.isEmpty ? href : text
        return [.link(text: label, url: url)]
    }

    private func itemTitleSegments(element: Element) throws -> [Segment] {
        let title = try normalizedText(from: element.text())
        guard !title.isEmpty else { return [] }

        var segments: [Segment] = [.heading(title)]

        if let descriptionText = try pairedItemDescriptionText(for: element) {
            segments.append(.text(descriptionText))
        }

        return segments
    }

    private func pairedItemDescriptionText(for titleElement: Element) throws -> String? {
        if let sibling = try titleElement.nextElementSibling() {
            let hook = try sibling.attr("data-hook")
            if hook == "item-description" {
                let text = try normalizedText(from: sibling.text())
                if !text.isEmpty { return text }
            }
        }

        if let parent = titleElement.parent(),
           let description = try parent.select("[data-hook=item-description]").first()
        {
            let text = try normalizedText(from: description.text())
            return text.isEmpty ? nil : text
        }

        return nil
    }

    // MARK: - Wix gallery JSON fallback

    private static let wixGalleryItemPattern = try! NSRegularExpression(
        pattern: #""description":"((?:\\.|[^"\\])*)"\s*,\s*"title":"((?:\\.|[^"\\])*)""#,
        options: []
    )

    private static func extractWixGalleryBlocks(from html: String) -> [ContentBlock] {
        let range = NSRange(html.startIndex..., in: html)
        var blocks: [ContentBlock] = []
        var seenTitles = Set<String>()

        wixGalleryItemPattern.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match,
                  match.numberOfRanges == 3,
                  let descriptionRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html)
            else { return }

            let rawDescription = String(html[descriptionRange])
            let rawTitle = String(html[titleRange])
            let title = unescapeJSONString(rawTitle)
            let text = unescapeJSONString(rawDescription)

            guard !title.isEmpty, !text.isEmpty else { return }
            guard seenTitles.insert(title).inserted else { return }

            blocks.append(ContentBlock(title: title, text: text, links: []))
        }

        return blocks
    }

    private static func unescapeJSONString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func enrichBlocks(_ blocks: [ContentBlock], with wixGalleryBlocks: [ContentBlock]) -> [ContentBlock] {
        guard !wixGalleryBlocks.isEmpty else { return blocks }

        let galleryTextByTitle = Dictionary(
            uniqueKeysWithValues: wixGalleryBlocks.compactMap { block -> (String, String)? in
                guard let title = block.title, !block.text.isEmpty else { return nil }
                return (title, block.text)
            }
        )

        return blocks.map { block in
            guard let title = block.title, block.text.isEmpty,
                  let galleryText = galleryTextByTitle[title]
            else {
                return block
            }

            return ContentBlock(title: title, text: galleryText, links: block.links)
        }
    }

    // MARK: - Heading detection

    private func isSemanticHeading(_ element: Element) throws -> Bool {
        let tag = element.tagName().lowercased()
        guard tag.hasPrefix("h"), tag.count == 2 else { return false }
        guard let level = Int(tag.dropFirst()), (1 ... 6).contains(level) else { return false }
        return true
    }

    private func isHeuristicHeading(_ element: Element) throws -> Bool {
        if try isSemanticHeading(element) { return false }

        let tag = element.tagName().lowercased()
        guard ["p", "div", "span", "li"].contains(tag) else { return false }

        for child in element.children() {
            let childTag = child.tagName().lowercased()
            if ["div", "p", "section", "article", "ul", "ol", "li"].contains(childTag) {
                let childText = try child.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if !childText.isEmpty { return false }
            }
        }

        let text = try normalizedText(from: element.text())
        guard !text.isEmpty, text.count <= 80 else { return false }
        guard !text.contains("\n") else { return false }

        let letters = text.filter(\.isLetter)
        let isUppercase = !letters.isEmpty && letters.allSatisfy(\.isUppercase)

        if isUppercase { return true }

        if let emphasis = try element.select("strong, b").first() {
            let emphasisText = try normalizedText(from: emphasis.text())
            return emphasisText == text
        }

        return false
    }

    // MARK: - Block assembly

    private func buildBlocks(from segments: [Segment]) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var currentTitle: String?
        var textParts: [String] = []
        var links: [ContentBlockLink] = []
        var seenLinkURLs = Set<String>()

        func flush() {
            let body = normalizedJoinedText(textParts)
            let dedupedLinks = links
            let hasContent = currentTitle != nil || !body.isEmpty || !dedupedLinks.isEmpty
            guard hasContent else {
                currentTitle = nil
                textParts = []
                links = []
                seenLinkURLs = []
                return
            }

            var finalText = body
            if let title = currentTitle, finalText == title {
                finalText = ""
            }

            blocks.append(ContentBlock(title: currentTitle, text: finalText, links: dedupedLinks))
            currentTitle = nil
            textParts = []
            links = []
            seenLinkURLs = []
        }

        for segment in segments {
            switch segment {
            case let .heading(title):
                flush()
                currentTitle = title

            case let .text(text):
                if text != currentTitle {
                    textParts.append(text)
                }

            case let .link(text, url):
                let key = url.absoluteString
                guard seenLinkURLs.insert(key).inserted else { continue }
                links.append(ContentBlockLink(text: text, url: url))
            }
        }

        flush()
        return blocks.filter { block in
            block.title != nil || !block.text.isEmpty || !block.links.isEmpty
        }
    }

    // MARK: - Text normalization

    private func normalizedText(from raw: String) -> String {
        raw
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func normalizedJoinedText(_ parts: [String]) -> String {
        parts
            .map { normalizedText(from: $0) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
