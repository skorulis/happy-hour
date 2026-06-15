//Created by Alex Skorulis on 15/6/2026.

import SwiftUI

struct VenueDetailsView: View {

    @State var viewModel: VenueDetailsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                locationSection
                linksSection
                metadataSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 360, minHeight: 400)
        .navigationTitle(viewModel.venue.name)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.venue.name)
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
            LabeledContent("Coordinates", value: viewModel.coordinateDescription)

            if let mapsURL = viewModel.mapsURL {
                Link("Open in Google Maps", destination: mapsURL)
            }
        }
    }

    @ViewBuilder
    private var linksSection: some View {
        if let websiteUri = viewModel.venue.websiteUri,
           let websiteURL = URL(string: websiteUri)
        {
            detailSection(title: "Links") {
                Link(websiteUri, destination: websiteURL)
            }
        }
    }

    private var metadataSection: some View {
        detailSection(title: "Details") {
            LabeledContent("Google Place ID", value: viewModel.venue.googleMapId)

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

#Preview {
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

    VenueDetailsView(viewModel: VenueDetailsViewModel(venue: venue))
}
