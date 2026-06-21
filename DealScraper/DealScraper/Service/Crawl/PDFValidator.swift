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
        guard let localURL = try? await fetcher.localFileURL(for: url, hash: hash) else {
            return nil
        }

        guard let extraction = textExtractor.extractText(from: localURL) else {
            return nil
        }

        return PDFValidationResult(url: url, text: extraction.filteredMarkdown)
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
