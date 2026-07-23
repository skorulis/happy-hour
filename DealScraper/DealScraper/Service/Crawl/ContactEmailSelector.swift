//Created by Alex Skorulis on 23/7/2026.

import Foundation

struct ContactEmailSelector {
    
    private static let invalidPrefixes: Set<String> = [
        "res.",
        "reservations",
        "catering",
        "events"
    ]
    
    private static let rankedPrefixes: [String: Int] = [
        "admin": 10,
        "info": 5,
        "contact": 5,
    ]

    func select(from emails: [String: Int]) -> String? {
        emails
            .filter { !Self.shouldIgnore($0.key) }
            .sorted { lhs, rhs in
                let lhsScore = Self.prefixScore(for: lhs.key)
                let rhsScore = Self.prefixScore(for: rhs.key)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return lhs.key < rhs.key
            }
            .first?
            .key
    }

    private static func localPart(of email: String) -> String {
        email
            .split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)?
            .lowercased() ?? ""
    }

    private static func prefixScore(for email: String) -> Int {
        let localPart = localPart(of: email)
        return rankedPrefixes
            .filter { localPart.hasPrefix($0.key) }
            .map(\.value)
            .max() ?? 0
    }

    private static func shouldIgnore(_ email: String) -> Bool {
        let localPart = localPart(of: email)
        
        let hasInvalidPreix = invalidPrefixes.contains { localPart.hasPrefix($0) }
        if hasInvalidPreix {
            return true
        }

        return false
    }
}
