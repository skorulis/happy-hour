//Created by Alex Skorulis on 18/6/2026.

import Foundation
import SwiftUI

struct VenueRow: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(venue.name)
                .font(.body.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var subtitle: String {
        if let address = formattedAddress(from: venue.json) {
            return address
        }
        return String(format: "%.4f, %.4f", venue.lat, venue.lng)
    }

    private func formattedAddress(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let place = try? JSONDecoder().decode(GooglePlace.self, from: data)
        else {
            return nil
        }
        return place.formattedAddress
    }
}
