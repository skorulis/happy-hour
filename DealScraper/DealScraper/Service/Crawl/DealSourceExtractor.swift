//Created by Alex Skorulis on 15/6/2026.

import Foundation
import SwiftSoup

struct DiscoveredSource: Equatable, Sendable {
    let url: URL
    let type: DealSourceType
    let hash: String
}

struct DealSourceExtractor {

    static let dealKeywords = [
        "happy hour",
        "specials",
        "what's on",
        "whats on",
        "events",
        "promotions",
        "deals",
        "menu",
        "drinks",
        "food",
    ]

    func extract(
        html: String,
        pageURL: URL,
        baseURL: URL,
        harvestedImageURLs: [URL] = []
    ) throws -> (sources: [DiscoveredSource], crawlLinks: [URL]) {
        let document = try SwiftSoup.parse(html, pageURL.absoluteString)
        let pageHasDealKeywords = Self.containsDealKeyword(Self.pageText(document, pageURL: pageURL))

        var sources: [DiscoveredSource] = []
        var crawlLinks: [URL] = []
        var seenHashes = Set<String>()

        func appendSource(url: URL, type: DealSourceType) {
            guard let normalized = URLNormalizer.normalize(url) else { return }
            let hash = URLNormalizer.hash(normalized)
            guard seenHashes.insert(hash).inserted else { return }
            sources.append(DiscoveredSource(url: normalized, type: type, hash: hash))
        }

        if pageHasDealKeywords {
            appendSource(url: pageURL, type: .webpage)
        }

        for link in try document.select("a[href]") {
            let href = try link.attr("href")
            guard let resolved = URLNormalizer.resolve(href, relativeTo: pageURL) else { continue }

            let linkText = try link.text()
            let hrefLower = href.lowercased()
            let matchesKeyword = Self.containsDealKeyword("\(linkText) \(hrefLower) \(resolved.path)")

            if hrefLower.hasSuffix(".pdf") || resolved.pathExtension.lowercased() == "pdf" {
                if matchesKeyword || pageHasDealKeywords {
                    appendSource(url: resolved, type: .pdf)
                }
                continue
            }

            if Self.isImageURL(resolved) {
                if matchesKeyword || pageHasDealKeywords {
                    appendSource(url: resolved, type: .image)
                }
                continue
            }

            if matchesKeyword, URLNormalizer.isSameOrigin(resolved, as: baseURL) {
                appendSource(url: resolved, type: .webpage)
                crawlLinks.append(resolved)
            }
        }

        if pageHasDealKeywords {
            for image in try document.select("img[src], img[srcset]") {
                let candidates = try imageSources(from: image)
                for candidate in candidates {
                    guard let resolved = URLNormalizer.resolve(candidate, relativeTo: pageURL) else { continue }
                    guard Self.isImageURL(resolved) else { continue }

                    let alt = (try? image.attr("alt")) ?? ""
                    let title = (try? image.attr("title")) ?? ""
                    let context = "\(alt) \(title) \(resolved.lastPathComponent)"

                    if Self.containsDealKeyword(context) || pageHasDealKeywords {
                        appendSource(url: resolved, type: .image)
                    }
                }
            }

            for imageURL in harvestedImageURLs {
                guard let resolved = URLNormalizer.resolve(imageURL.absoluteString, relativeTo: pageURL) else { continue }
                guard Self.isImageURL(resolved) else { continue }
                appendSource(url: resolved, type: .image)
            }
        }

        return (sources, crawlLinks)
    }

    private func imageSources(from element: Element) throws -> [String] {
        var sources: [String] = []
        let src = try element.attr("src")
        if !src.isEmpty {
            sources.append(src)
        }

        let srcset = try element.attr("srcset")
        if !srcset.isEmpty {
            let parsed = srcset
                .split(separator: ",")
                .compactMap { part -> String? in
                    let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                    let urlPart = trimmed.split(separator: " ").first.map(String.init)
                    return urlPart?.isEmpty == false ? urlPart : nil
                }
            sources.append(contentsOf: parsed)
        }

        return sources
    }

    private static func pageText(_ document: Document, pageURL: URL) -> String {
        let title = (try? document.title()) ?? ""
        return "\(title) \(pageURL.absoluteString) \(pageURL.path)"
    }

    private static func containsDealKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return dealKeywords.contains { lowercased.contains($0) }
    }

    private static func isImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "svg", "avif"]
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) {
            return true
        }
        return url.absoluteString.lowercased().contains("image")
    }
}
