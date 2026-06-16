//Created by Alex Skorulis on 15/6/2026.

import Foundation
import SwiftSoup

struct PageLinkExtractor {

    func extract(html: String, pageURL: URL) throws -> [ContentBlockLink] {
        let document = try SwiftSoup.parse(html, pageURL.absoluteString)
        var links: [ContentBlockLink] = []
        var seenURLs = Set<String>()

        for element in try document.select("a[href]") {
            let href = try element.attr("href")
            guard let url = URLNormalizer.resolve(href, relativeTo: pageURL) else { continue }

            let key = url.absoluteString
            guard seenURLs.insert(key).inserted else { continue }

            let text = try linkText(from: element, href: href)
            links.append(ContentBlockLink(text: text, url: url))
        }

        return links
    }

    private func linkText(from element: Element, href: String) throws -> String? {
        let visibleText = normalizedText(from: try element.text())
        if !visibleText.isEmpty { return visibleText }

        let titleText = normalizedText(from: try element.attr("title"))
        if !titleText.isEmpty { return titleText }

        let trimmedHref = href.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedHref.isEmpty ? nil : trimmedHref
    }

    private func normalizedText(from raw: String) -> String {
        raw
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
