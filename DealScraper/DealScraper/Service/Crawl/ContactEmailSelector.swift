//Created by Alex Skorulis on 23/7/2026.

import Foundation

struct ContactEmailSelector {
    
    private static let invalidPrefixes: Set<String> = [
        "res.",
        "reservations",
        "catering",
        "events"
    ]

    func select(from emails: [String: Int]) -> String? {
        emails
            .filter { !Self.shouldIgnore($0.key) }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return lhs.key < rhs.key
            }
            .first?
            .key
    }

    private static func shouldIgnore(_ email: String) -> Bool {
        let localPart = email
            .split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .lowercased() ?? ""
        
        let hasInvalidPreix = invalidPrefixes.contains { localPart.hasPrefix($0) }
        if hasInvalidPreix {
            return true
        }

        return false
    }
}
