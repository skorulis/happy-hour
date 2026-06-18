//Created by Alex Skorulis on 19/6/2026.

import Foundation
import KnitMacros
import Knit

struct PDFValidationResult: Equatable, Sendable {
    let url: URL
    let text: String
}

@MainActor
final class PDFValidator {

    private let fetcher: CrawlPDFFetcher
    private let textExtractor: PDFTextExtractor

    @Resolvable<Resolver>
    init(fetcher: CrawlPDFFetcher, textExtractor: PDFTextExtractor) {
        self.fetcher = fetcher
        self.textExtractor = textExtractor
    }

    func validatePDF(url: URL, hash: String) async -> PDFValidationResult? {
        guard !Self.shouldIgnore(url: url) else {
            return nil
        }

        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return nil
        }

        guard let text = textExtractor.extractText(from: localURL),
              !text.isEmpty,
              PageLinkFilter.containsDealKeyword(text)
        else {
            return nil
        }

        return PDFValidationResult(url: url, text: text)
    }

    func validatePDFs(urls: [URL]) async -> [PDFValidationResult] {
        var results: [PDFValidationResult] = []
        for url in urls {
            let hash = URLNormalizer.hash(url)
            if let validation = await validatePDF(url: url, hash: hash) {
                results.append(validation)
            }
        }
        return PDFVersionFilter.filterToLatestVersions(results)
    }

    private static func shouldIgnore(url: URL) -> Bool {
        let absoluteString = url.absoluteString.lowercased()
        return PageLinkFilter.excludedKeywords.contains { absoluteString.contains($0) }
    }
}

enum PDFVersionFilter {

    static func filterToLatestVersions(_ results: [PDFValidationResult]) -> [PDFValidationResult] {
        let grouped = Dictionary(grouping: results) { versionStem(for: $0.url) }

        return grouped.values.flatMap { group in
            let years = group.map { year(from: $0.url) }
            guard years.contains(where: { $0 != nil }) else {
                return group
            }

            let maxYear = years.compactMap(\.self).max()
            guard let maxYear else {
                return group
            }

            return group.filter { year(from: $0.url) == maxYear }
        }
    }

    static func year(from url: URL) -> Int? {
        let range = NSRange(url.path.startIndex..., in: url.path)
        guard let regex = try? NSRegularExpression(pattern: #"\b(20\d{2})\b"#),
              let match = regex.firstMatch(in: url.path, range: range),
              let yearRange = Range(match.range(at: 1), in: url.path)
        else {
            return nil
        }
        return Int(url.path[yearRange])
    }

    static func versionStem(for url: URL) -> String {
        var stem = url.deletingPathExtension().path.lowercased()
        let range = NSRange(stem.startIndex..., in: stem)
        guard let regex = try? NSRegularExpression(pattern: #"\b20\d{2}\b"#) else {
            return stem
        }
        stem = regex.stringByReplacingMatches(
            in: stem,
            range: range,
            withTemplate: ""
        )
        while stem.hasSuffix("-") {
            stem.removeLast()
        }
        return stem
    }
}
