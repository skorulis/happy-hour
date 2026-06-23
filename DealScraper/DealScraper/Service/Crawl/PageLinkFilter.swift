//Created by Alex Skorulis on 17/6/2026.

import Foundation

struct FilteredPageLinks: Equatable, Sendable {
    let pdfURLs: [URL]
    let crawlURLs: [URL]
}

struct PageLinkFilter {

    func filter(links: [ContentBlockLink]) -> FilteredPageLinks {
        var pdfURLs: [URL] = []
        var crawlURLs: [URL] = []
        var seenPDFHashes = Set<String>()
        var seenCrawlHashes = Set<String>()

        for link in links {
            guard shouldInclude(link) else { continue }
            guard let normalized = URLNormalizer.normalize(link.url) else { continue }

            switch Self.sourceType(for: normalized) {
            case .pdf:
                let hash = URLNormalizer.hash(normalized)
                guard seenPDFHashes.insert(hash).inserted else { continue }
                pdfURLs.append(normalized)
            case .webpage:
                let hash = URLNormalizer.hash(normalized)
                guard seenCrawlHashes.insert(hash).inserted else { continue }
                crawlURLs.append(normalized)
            case .image:
                continue
            }
        }

        return FilteredPageLinks(pdfURLs: pdfURLs, crawlURLs: crawlURLs)
    }

    func shouldInclude(_ link: ContentBlockLink) -> Bool {
        if Self.isYearSpecificEventsLink(link.url) {
            return false
        }
        let context = linkContext(link)
        if FilterKeywords.containsExcludedKeyword(context) {
            return false
        }
        if Self.sourceType(for: link.url) == .pdf {
            return true
        }
        if DealDay.isMentioned(in: context) {
            return true
        }
        if FilterKeywords.containsDealKeyword(context) {
            return true
        }
        return false
    }

    static func sourceType(for url: URL) -> DealSourceType {
        if url.pathExtension.lowercased() == "pdf"
            || url.absoluteString.lowercased().hasSuffix(".pdf") {
            return .pdf
        }

        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "svg", "avif"]
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext)
            || url.absoluteString.lowercased().contains("image") {
            return .image
        }

        return .webpage
    }

    private func linkContext(_ link: ContentBlockLink) -> String {
        let text = link.text ?? ""
        return "\(text) \(link.url.path) \(link.url.absoluteString)"
    }

    private static func isYearSpecificEventsLink(_ url: URL) -> Bool {
        let components = url.path.split(separator: "/").map { String($0).lowercased() }
        for (index, component) in components.enumerated() {
            guard component == "events" || component == "event" else { continue }
            guard index + 1 < components.count else { continue }
            let yearComponent = components[index + 1]
            guard yearComponent.count == 4,
                  yearComponent.hasPrefix("20"),
                  Int(yearComponent) != nil
            else {
                continue
            }
            return true
        }
        return false
    }
}
