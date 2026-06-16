//Created by Alex Skorulis on 15/6/2026.

import Foundation
import SwiftSoup

struct DiscoveredSource: Equatable, Sendable {
    let url: URL
    let type: DealSourceType
    let imageDimensions: CGSize?
    let textPieces: DealSourceTextPieces?

    init(
        url: URL,
        type: DealSourceType,
        imageDimensions: CGSize? = nil,
        textPieces: DealSourceTextPieces? = nil
    ) {
        self.url = url
        self.type = type
        self.imageDimensions = imageDimensions
        self.textPieces = textPieces
    }
}

struct DealSourceExtractor {

    func extract(page: LoadedPage) throws -> [DiscoveredSource] {
        let pageURL = page.url
        let document = try SwiftSoup.parse(page.html, pageURL.absoluteString)
        let pageHasDealKeywords = PageLinkFilter.containsDealKeyword(Self.pageText(document, pageURL: pageURL))

        var sources: [DiscoveredSource] = []
        var seenHashes = Set<String>()

        func appendSource(url: URL, type: DealSourceType) {
            guard let normalized = URLNormalizer.normalize(url) else { return }
            let hash = URLNormalizer.hash(normalized)
            guard seenHashes.insert(hash).inserted else { return }
            sources.append(DiscoveredSource(url: normalized, type: type))
        }

        for image in try document.select("img[src], img[srcset]") {
            let candidates = try imageSources(from: image)
            for candidate in candidates {
                guard let resolved = URLNormalizer.resolve(candidate, relativeTo: pageURL) else { continue }
                guard PageLinkFilter.isImageURL(resolved) else { continue }

                let alt = (try? image.attr("alt")) ?? ""
                let title = (try? image.attr("title")) ?? ""
                let context = "\(alt) \(title) \(resolved.lastPathComponent)"

                if PageLinkFilter.containsDealKeyword(context) || pageHasDealKeywords {
                    appendSource(url: resolved, type: .image)
                }
            }
        }

        return sources
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
}
