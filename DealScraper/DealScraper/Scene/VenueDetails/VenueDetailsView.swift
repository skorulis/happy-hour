//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct VenueDetailsView: View {

    @State var viewModel: VenueDetailsViewModel

    var body: some View {
        Group {
            if let venue = viewModel.venue {
                venueContent(venue)
            } else {
                ContentUnavailableView(
                    "Venue Not Found",
                    systemImage: "building.2",
                    description: Text("This venue is no longer saved locally.")
                )
            }
        }
        .frame(minWidth: 360, minHeight: 400)
        .navigationTitle(viewModel.venue?.name ?? "Venue")
    }

    private func venueContent(_ venue: Venue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(venue)
                locationSection
                linksSection(venue)
                actionsSection
                metadataSection(venue)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func header(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(venue.name)
                .font(.largeTitle.weight(.semibold))

            if let address = viewModel.formattedAddress {
                Text(address)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        detailSection(title: "Location") {
            if let coordinateDescription = viewModel.coordinateDescription {
                LabeledContent("Coordinates", value: coordinateDescription)
            }

            if let mapsURL = viewModel.mapsURL {
                Link("Open in Google Maps", destination: mapsURL)
            }
        }
    }

    @ViewBuilder
    private func linksSection(_ venue: Venue) -> some View {
        if let websiteUri = venue.websiteUri,
           let websiteURL = URL(string: websiteUri)
        {
            detailSection(title: "Links") {
                Link(websiteUri, destination: websiteURL)
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        detailSection(title: "Actions") {
            Button("Crawl Website") {
                viewModel.crawlWebsite()
            }
            .disabled(!viewModel.canCrawl)

            switch viewModel.crawlState {
            case .idle:
                if viewModel.venue?.websiteUri == nil {
                    Text("Add a website URL via Google Places import to enable crawling.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .crawling(progress):
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(progress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .completed(found):
                Text("Found \(found) new deal source\(found == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func metadataSection(_ venue: Venue) -> some View {
        detailSection(title: "Details") {
            LabeledContent("Google Place ID", value: venue.googleMapId)

            if !viewModel.types.isEmpty {
                LabeledContent("Types", value: viewModel.types.joined(separator: ", "))
            }

            if let lastCrawlDescription = viewModel.lastCrawlDescription {
                LabeledContent("Last Crawled", value: lastCrawlDescription)
            }
        }
    }

    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}

@MainActor
private func venueDetailsPreview() -> some View {
    let assembler = DealScraperAssembly.testing()
    let repository = assembler.resolver.venueRepository()
    let venue = Venue(
        googleMapId: "ChIJpreview",
        name: "The Local Pub",
        lat: -33.8688,
        lng: 151.2093,
        websiteUri: "https://example.com",
        lastCrawlDate: .now,
        json: """
        {"displayName":{"text":"The Local Pub"},"formattedAddress":"123 George St, Sydney","id":"ChIJpreview","location":{"latitude":-33.8688,"longitude":151.2093},"types":["bar","restaurant"],"websiteUri":"https://example.com"}
        """
    )
    try! repository.upsert(venue)

    return VenueDetailsView(
        viewModel: assembler.resolver.venueDetailsViewModel(googleID: venue.googleMapId)
    )
}

#Preview {
    venueDetailsPreview()
}
