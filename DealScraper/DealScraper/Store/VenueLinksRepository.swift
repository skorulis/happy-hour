//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class VenueLinksRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func find(venueId: Int64) throws -> VenueLinks? {
        try store.dbQueue.read { db in
            try VenueLinks.fetchOne(db, key: venueId)
        }
    }

    func setMissing(
        venueId: Int64,
        whatsOn: String?,
        instagram: String?,
        facebook: String?
    ) throws {
        let discoveredWhatsOn = Self.nonEmpty(whatsOn)
        let discoveredInstagram = Self.nonEmpty(instagram)
        let discoveredFacebook = Self.nonEmpty(facebook)

        guard discoveredWhatsOn != nil || discoveredInstagram != nil || discoveredFacebook != nil else {
            return
        }

        try store.dbQueue.write { db in
            if let existing = try VenueLinks.fetchOne(db, key: venueId) {
                var updated = existing
                var changed = false

                if updated.whatsOn == nil || updated.whatsOn?.isEmpty == true,
                   let discoveredWhatsOn
                {
                    updated.whatsOn = discoveredWhatsOn
                    changed = true
                }

                if updated.instagram == nil || updated.instagram?.isEmpty == true,
                   let discoveredInstagram
                {
                    updated.instagram = discoveredInstagram
                    changed = true
                }

                if updated.facebook == nil || updated.facebook?.isEmpty == true,
                   let discoveredFacebook
                {
                    updated.facebook = discoveredFacebook
                    changed = true
                }

                if changed {
                    try updated.update(db)
                    try Venue.touchLastUpdate(db, venueId: venueId)
                }
            } else {
                var links = VenueLinks(
                    venueId: venueId,
                    whatsOn: discoveredWhatsOn,
                    instagram: discoveredInstagram,
                    facebook: discoveredFacebook
                )
                try links.insert(db)
                try Venue.touchLastUpdate(db, venueId: venueId)
            }
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
