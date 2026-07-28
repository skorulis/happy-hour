//Created by Alex Skorulis on 15/6/2026.

import CryptoKit
import Foundation

enum URLNormalizer {

    /// Query parameter names on Google Business Profile website links.
    private static let googleTrackingQueryNames: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term",
    ]

    static func stripGoogleTrackingParameters(from urlString: String) -> String {
        guard var components = URLComponents(string: urlString),
              let queryItems = components.queryItems,
              !queryItems.isEmpty
        else {
            return urlString
        }

        let filtered = queryItems.filter {
            !googleTrackingQueryNames.contains($0.name.lowercased())
        }

        if filtered.count == queryItems.count {
            return urlString
        }

        components.queryItems = filtered.isEmpty ? nil : filtered
        return components.url?.absoluteString ?? urlString
    }

    static func resolve(_ urlString: String, relativeTo baseURL: URL) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("#") { return nil }

        if let absolute = URL(string: trimmed), absolute.scheme != nil {
            return normalize(absolute)
        }

        guard let resolved = URL(string: trimmed, relativeTo: baseURL) else { return nil }
        return normalize(resolved)
    }

    static func normalize(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        guard let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }

        // Preserve http vs https. Many venue sites only redirect correctly over http;
        // forcing https hits broken certs and never reaches the real destination.
        components.scheme = scheme
        if let host = components.host {
            components.host = host.lowercased()
        }
        components.fragment = nil

        guard let normalized = components.url else { return nil }

        var path = normalized.path
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }

        var result = URLComponents(url: normalized, resolvingAgainstBaseURL: false)
        result?.path = path
        return result?.url ?? normalized
    }

    static func hash(_ url: URL) -> String {
        // Treat http/https as the same page identity for visit / cache keys.
        let canonical = canonicalForIdentity(url) ?? url
        let data = Data(canonical.absoluteString.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func hash(urlString: String, relativeTo baseURL: URL) -> String? {
        guard let url = resolve(urlString, relativeTo: baseURL) else { return nil }
        return hash(url)
    }

    static func isSameOrigin(_ url: URL, as baseURL: URL) -> Bool {
        guard let normalized = normalize(url),
              let normalizedBase = normalize(baseURL),
              let host = normalized.host,
              let baseHost = normalizedBase.host
        else {
            return false
        }

        return canonicalHost(host) == canonicalHost(baseHost)
    }

    private static func canonicalForIdentity(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        if components.scheme?.lowercased() == "http" {
            components.scheme = "https"
        }
        if let host = components.host {
            components.host = host.lowercased()
        }
        components.fragment = nil
        return components.url
    }

    private static func canonicalHost(_ host: String) -> String {
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }
}
