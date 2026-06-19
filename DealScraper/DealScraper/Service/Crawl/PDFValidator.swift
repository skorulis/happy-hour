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
        let urlsToProcess = PDFVersionFilter.filterToLatestVersions(urls)
        var results: [PDFValidationResult] = []
        for url in urlsToProcess {
            let hash = URLNormalizer.hash(url)
            if let validation = await validatePDF(url: url, hash: hash) {
                results.append(validation)
            }
        }
        return results
    }

    private static func shouldIgnore(url: URL) -> Bool {
        let absoluteString = url.absoluteString.lowercased()
        return PageLinkFilter.excludedKeywords.contains { absoluteString.contains($0) }
    }
}

enum PDFVersionFilter {

    static func filterToLatestVersions(
        _ urls: [URL],
        currentYear: Int = Calendar.current.component(.year, from: Date())
    ) -> [URL] {
        urls.filter { url in
            guard let year = year(from: url) else {
                return true
            }
            return year >= currentYear
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
}
