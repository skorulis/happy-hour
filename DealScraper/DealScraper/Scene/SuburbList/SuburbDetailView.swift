// Created by Alexander Skorulis on 19/7/2026.

import SwiftUI

struct SuburbDetailView: View {

    @State var viewModel: SuburbDetailViewModel
    @State private var showVenueHeroPicker = false

    var body: some View {
        Group {
            if let suburb = viewModel.suburb {
                suburbContent(suburb)
            } else {
                ContentUnavailableView(
                    "Suburb Not Found",
                    systemImage: "building.2",
                    description: Text("This suburb is no longer saved locally.")
                )
            }
        }
        .sheet(isPresented: $showVenueHeroPicker) {
            SuburbVenueHeroPickerView(venues: viewModel.venues) { venue in
                guard let url = venue.heroImage else { return }
                await viewModel.setHeroImage(urlString: url)
            }
        }
    }

    private func suburbContent(_ suburb: Suburb) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(suburb)
            Divider()
            venueList
        }
    }

    private func header(_ suburb: Suburb) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        details(suburb: suburb)

                        Spacer(minLength: 16)

                        HStack(spacing: 8) {
                            Button("Crawl") {
                                viewModel.crawl()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Crawl all websites") {
                                viewModel.crawlAllWebsites()
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.venues.isEmpty)
                        }
                    }

                    if let actionMessage = viewModel.actionMessage {
                        Text(actionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)

                VStack(alignment: .trailing, spacing: 8) {
                    HeroImagePickerView(
                        imageURL: suburb.heroImage,
                        canClear: viewModel.canClearHeroImage,
                        onClear: { viewModel.clearHeroImage() },
                        onSetURL: { urlString in
                            await viewModel.setHeroImage(urlString: urlString)
                        }
                    )
                    .frame(maxHeight: 200)

                    Button("Select from venues") {
                        showVenueHeroPicker = true
                    }
                    .disabled(viewModel.venuesWithHeroImages.isEmpty)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }
    
    private func details(suburb: Suburb) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(SuburbListViewModel.displayName(for: suburb))
                .font(.title2)
                .fontWeight(.semibold)

            if let state = suburb.state, !state.isEmpty {
                Text(state)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let countryName = viewModel.countryName, !countryName.isEmpty {
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
    }

    @ViewBuilder
    private var venueList: some View {
        if viewModel.venues.isEmpty {
            ContentUnavailableView(
                "No Venues",
                systemImage: "building.2",
                description: Text("No venues are linked to this suburb yet. Run a crawl to find some.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section("\(viewModel.venues.count) venue\(viewModel.venues.count == 1 ? "" : "s")") {
                    ForEach(viewModel.venues, id: \.googleMapId) { venue in
                        Button {
                            viewModel.openVenueDetails(googleMapId: venue.googleMapId)
                        } label: {
                            VenueRow(
                                venue: venue,
                                sourceCount: viewModel.sourceCount(for: venue),
                                dealCount: viewModel.dealCount(for: venue)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
