//Created by Alex Skorulis on 23/7/2026.

import Foundation

struct EmailExtractor {

    private static let pattern = try! NSRegularExpression(
        pattern: #"(?:mailto:)?[A-Z0-9._%+-]+@(?!\d+x\.)[A-Z0-9.-]+\.[A-Z]{2,}"#,
        options: .caseInsensitive
    )

    /// Platform telemetry / tooling addresses embedded in page source, not venue contacts.
    private static let ignoredDomainSuffixes = [
        "wixpress.com",
        "sentry.io",
    ]

    func extract(from text: String) -> Set<String> {
        var emails = Set<String>()
        let range = NSRange(text.startIndex..., in: text)
        Self.pattern.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: text) else { return }
            var email = String(text[matchRange])
            if email.lowercased().hasPrefix("mailto:") {
                email = String(email.dropFirst("mailto:".count))
            }
            email = email.lowercased()
            guard !Self.shouldIgnore(email) else { return }
            emails.insert(email)
        }
        return emails
    }

    private static func shouldIgnore(_ email: String) -> Bool {
        guard let at = email.lastIndex(of: "@") else { return true }
        let domain = String(email[email.index(after: at)...])
        return ignoredDomainSuffixes.contains { suffix in
            domain == suffix || domain.hasSuffix("." + suffix)
        }
    }
}
