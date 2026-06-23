//Created by Alex Skorulis on 23/6/2026.

import Foundation
import SwiftSoup

struct CanonicalURLExtractor {

    func extract(html: String, pageURL: URL) throws -> URL? {
        let document = try SwiftSoup.parse(html, pageURL.absoluteString)

        for element in try document.select("link[href]") {
            let rel = try element.attr("rel").lowercased()
            let tokens = rel.split(whereSeparator: { $0.isWhitespace })
            guard tokens.contains("canonical") else { continue }

            let href = try element.attr("href")
            guard let resolved = URLNormalizer.resolve(href, relativeTo: pageURL),
                  let normalized = URLNormalizer.normalize(resolved),
                  URLNormalizer.isSameOrigin(normalized, as: pageURL)
            else {
                continue
            }

            return normalized
        }

        return nil
    }
}
