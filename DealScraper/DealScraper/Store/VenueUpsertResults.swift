//Created by Alex Skorulis on 27/7/2026.

import Foundation

struct VenueUpsertResults: Equatable, Sendable {
    let newVenues: Int
    /// Places skipped before insert/update (closed, missing address, or unparseable address).
    let droppedVenues: Int
}
