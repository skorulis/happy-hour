// Created by Alexander Skorulis on 19/7/2026.

import SwiftUI

struct SuburbDetailView: View {

    let suburb: Suburb
    let countryName: String?
    let venues: [Venue]
    let actionMessage: String?
    let onCrawl: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            venueList
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(SuburbListViewModel.displayName(for: suburb))
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let state = suburb.state, !state.isEmpty {
                        Text(state)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let countryName, !countryName.isEmpty {
                        Text(countryName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let statisticArea = suburb.statisticArea, !statisticArea.isEmpty {
                        Text(statisticArea)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let lastCrawlDate = suburb.lastCrawlDate {
                        Text("Last crawled \(lastCrawlDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never crawled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Crawl", action: onCrawl)
                    .buttonStyle(.borderedProminent)
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    @ViewBuilder
    private var venueList: some View {
        if venues.isEmpty {
            ContentUnavailableView(
                "No Venues",
                systemImage: "building.2",
                description: Text("No venues are linked to this suburb yet. Run a crawl to find some.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section("\(venues.count) venue\(venues.count == 1 ? "" : "s")") {
                    ForEach(venues, id: \.googleMapId) { venue in
                        Text(venue.name)
                    }
                }
            }
        }
    }
}
