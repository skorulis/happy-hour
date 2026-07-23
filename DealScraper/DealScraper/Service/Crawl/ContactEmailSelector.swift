//Created by Alex Skorulis on 23/7/2026.

import Foundation

struct ContactEmailSelector {

    func select(from emails: Set<String>) -> String? {
        emails
            .filter { !Self.shouldIgnore($0) }
            .sorted()
            .first
    }

    private static func shouldIgnore(_ email: String) -> Bool {
        let localPart = email
            .split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .lowercased() ?? ""

        return localPart.hasPrefix("res.") || localPart.hasPrefix("reservations")
    }
}
