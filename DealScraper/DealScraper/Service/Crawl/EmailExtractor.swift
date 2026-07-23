//Created by Alex Skorulis on 23/7/2026.

import Foundation

struct EmailExtractor {

    private static let pattern = try! NSRegularExpression(
        pattern: #"(?:mailto:)?[A-Z0-9._%+-]+@(?!\d+x\.)[A-Z0-9.-]+\.[A-Z]{2,}"#,
        options: .caseInsensitive
    )

    func extract(from text: String) -> Set<String> {
        var emails = Set<String>()
        let range = NSRange(text.startIndex..., in: text)
        Self.pattern.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: text) else { return }
            var email = String(text[matchRange])
            if email.lowercased().hasPrefix("mailto:") {
                email = String(email.dropFirst("mailto:".count))
            }
            emails.insert(email.lowercased())
        }
        return emails
    }
}
