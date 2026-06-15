//Created by Alex Skorulis on 15/6/2026.

import Foundation
import SwiftSoup

struct DiscoveredVenueLinks: Equatable, Sendable {
    var whatsOn: URL?
    var instagram: URL?
    var facebook: URL?
}

struct VenueLinkExtractor {

    static let whatsOnKeywords = [
        "what's on",
        "whats on",
        "events",
        "specials",
        "promotions",
    ]

    func extract(
        html: String,
        pageURL: URL,
        baseURL: URL
    ) throws -> DiscoveredVenueLinks {
        let document = try SwiftSoup.parse(html, pageURL.absoluteString)
        var links = DiscoveredVenueLinks()

        for link in try document.select("a[href]") {
            let href = try link.attr("href")
            guard let resolved = URLNormalizer.resolve(href, relativeTo: pageURL),
                  let normalized = URLNormalizer.normalize(resolved)
            else { continue }

            if links.whatsOn == nil,
               URLNormalizer.isSameOrigin(normalized, as: baseURL),
               Self.matchesWhatsOnKeyword(link: link, href: href, resolved: normalized)
            {
                links.whatsOn = normalized
            }

            if links.instagram == nil, Self.isInstagramURL(normalized) {
                links.instagram = normalized
            }

            if links.facebook == nil, Self.isFacebookURL(normalized) {
                links.facebook = normalized
            }

            if links.whatsOn != nil, links.instagram != nil, links.facebook != nil {
                break
            }
        }

        return links
    }

    private static func matchesWhatsOnKeyword(
        link: Element,
        href: String,
        resolved: URL
    ) -> Bool {
        let linkText = (try? link.text()) ?? ""
        let context = "\(linkText) \(href) \(resolved.path)".lowercased()
        return whatsOnKeywords.contains { context.contains($0) }
    }

    private static func isInstagramURL(_ url: URL) -> Bool {
        url.host?.lowercased().contains("instagram.com") == true
    }

    private static func isFacebookURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("facebook.com") || host.contains("fb.com")
    }
}
