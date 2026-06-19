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
        let context = linkContext(link)
        if Self.containsExcludedKeyword(context) {
            return false
        }
        if Self.sourceType(for: link.url) == .pdf {
            return true
        }
        if DealDay.isMentioned(in: context) {
            return true
        }
        if Self.containsDealKeyword(context) {
            return true
        }
        return false
    }

    static func containsDealKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return FilterKeywords.dealKeywords.contains { lowercased.contains($0) }
    }
    
    private static func containsExcludedKeyword(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return FilterKeywords.excludedKeywords.contains { lowercased.contains($0) }
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
}
