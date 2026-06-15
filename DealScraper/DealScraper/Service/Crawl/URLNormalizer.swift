//Created by Alex Skorulis on 15/6/2026.

import CryptoKit
import Foundation

enum URLNormalizer {

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

        components.scheme = "https"
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
        let data = Data(url.absoluteString.utf8)
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

        return host == baseHost && normalized.scheme == normalizedBase.scheme
    }
}
