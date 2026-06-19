//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct VenueDetailsView: View {

    @State var viewModel: VenueDetailsViewModel
    @State private var selectedTab: VenueDetailsTab = .details

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
        .navigationTitle(viewModel.venue.map(venueTitle) ?? "Venue")
    }

    private func venueContent(_ venue: Venue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(venue)

                switch selectedTab {
                case .details:
                    locationSection
                    linksSection(venue)
                    actionsSection
                    metadataSection(venue)
                case .dealSources:
                    dealSourcesSection
                case .deals:
                    dealsSection
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func venueTitle(_ venue: Venue) -> String {
        guard let id = venue.id else { return venue.name }
        return "\(venue.name) #\(id)"
    }

    private func header(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(venue.name)
                    .font(.largeTitle.weight(.semibold))

                if let id = venue.id {
                    Text("#\(id)")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if let address = viewModel.formattedAddress {
                Text(address)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Picker("Section", selection: $selectedTab) {
                ForEach(VenueDetailsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)
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
        let hasWebsite = venue.websiteUri.flatMap(URL.init(string:)) != nil
        let hasWhatsOn = viewModel.venueLinks?.whatsOn.flatMap(URL.init(string:)) != nil
        let hasInstagram = viewModel.venueLinks?.instagram.flatMap(URL.init(string:)) != nil
        let hasFacebook = viewModel.venueLinks?.facebook.flatMap(URL.init(string:)) != nil

        if hasWebsite || hasWhatsOn || hasInstagram || hasFacebook {
            detailSection(title: "Links") {
                if let websiteUri = venue.websiteUri,
                   let websiteURL = URL(string: websiteUri)
                {
                    Link("Website", destination: websiteURL)
                }

                if let whatsOn = viewModel.venueLinks?.whatsOn,
                   let whatsOnURL = URL(string: whatsOn)
                {
                    Link("What's On", destination: whatsOnURL)
                }

                if let instagram = viewModel.venueLinks?.instagram,
                   let instagramURL = URL(string: instagram)
                {
                    Link("Instagram", destination: instagramURL)
                }

                if let facebook = viewModel.venueLinks?.facebook,
                   let facebookURL = URL(string: facebook)
                {
                    Link("Facebook", destination: facebookURL)
                }
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        detailSection(title: "Actions") {
            HStack {
                Button("Crawl Website") {
                    viewModel.crawlWebsite()
                }
                .disabled(!viewModel.canCrawl)

                Button("Delete Sources", role: .destructive) {
                    viewModel.deleteSources()
                }
                .disabled(!viewModel.canDeleteSources)
            }

            switch viewModel.crawlState {
            case .idle:
                if viewModel.venue?.websiteUri == nil {
                    Text("Add a website URL via Google Places import to enable crawling.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .inProgress(progress):
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(progress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .completed(results):
                crawlResultsView(results)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            switch viewModel.deleteSourcesState {
            case .idle:
                EmptyView()
            case let .completed(deleted):
                Text("Deleted \(deleted) deal source\(deleted == 1 ? "" : "s").")
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

    @ViewBuilder
    private func crawlResultsView(_ results: VenueCrawlResults) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Found \(results.dealsFound) new deal source\(results.dealsFound == 1 ? "" : "s").")
            Text("Analyzed \(results.imagesAnalyzed) image\(results.imagesAnalyzed == 1 ? "" : "s").")
            Text("Completed in \(formattedDuration(results.duration)).")

            if !results.visitedPages.isEmpty {
                Text("Visited \(results.visitedPages.count) page\(results.visitedPages.count == 1 ? "" : "s"):")
                    .padding(.top, 4)

                ForEach(Array(results.visitedPages.enumerated()), id: \.offset) { _, url in
                    Link(url.absoluteString, destination: url)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1f seconds", duration)
        }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if seconds == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        return "\(minutes)m \(seconds)s"
    }

    private func extractionResultsView(_ results: VenueDealExtractionResults) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Found \(results.dealsFound) deals condensed from \(results.dealsFoundBeforeCondensing)")
            Text("\(results.errorCount) error\(results.errorCount == 1 ? "" : "s").")
            Text("Completed in \(formattedDuration(results.duration)).")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var dealSourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            extractionSection

            if viewModel.dealSources.isEmpty {
                ContentUnavailableView(
                    "No Deal Sources",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Crawl the venue website from the Details tab to discover deal sources.")
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deal Sources")
                        .font(.headline)

                    ForEach(viewModel.dealSources, id: \.url) { source in
                        DealSourceRow(source: source) { status in
                            viewModel.setDealSourceStatus(source, status: status)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var extractionSection: some View {
        detailSection(title: "Extract Deals") {
            TextField("OpenRouter model", text: $viewModel.openRouterModel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Extract Deals") {
                    viewModel.extractDeals()
                }
                .disabled(!viewModel.canExtractDeals)

                Button("Delete Deals", role: .destructive) {
                    viewModel.deleteDeals()
                }
                .disabled(!viewModel.canDeleteDeals)
            }

            Text("\(viewModel.approvedSourceCount) approved source\(viewModel.approvedSourceCount == 1 ? "" : "s") ready for extraction.")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch viewModel.extractionState {
            case .idle:
                EmptyView()
            case let .extracting(progress):
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(progress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .completed(results):
                extractionResultsView(results)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            switch viewModel.deleteDealsState {
            case .idle:
                EmptyView()
            case let .completed(deleted):
                Text("Deleted \(deleted) deal\(deleted == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var dealsSection: some View {
        if viewModel.deals.isEmpty {
            ContentUnavailableView(
                "No Deals",
                systemImage: "tag",
                description: Text("Approve deal sources and run extraction from the Deal Sources tab.")
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Deals")
                    .font(.headline)

                ForEach(viewModel.deals, id: \.deal.id) { item in
                    DealRow(item: item) { status in
                        viewModel.setDealStatus(item, status: status)
                    }
                }
            }
        }
    }
}

private enum VenueDetailsTab: String, CaseIterable {
    case details = "Details"
    case dealSources = "Deal Sources"
    case deals = "Deals"
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
    let venueId = try! repository.find(googleMapId: venue.googleMapId)!.id!
    try! assembler.resolver.venueLinksRepository().setMissing(
        venueId: venueId,
        whatsOn: "https://example.com/whats-on",
        instagram: "https://instagram.com/thelocalpub",
        facebook: "https://facebook.com/thelocalpub"
    )
    try! assembler.resolver.dealSourceRepository().upsert(
        sources: [
            DealSource(
                venueId: venueId,
                url: "https://example.com/happy-hour",
                type: .webpage,
                textPieces: .textLines([
                    "Happy Hour Mon–Fri 4–6pm",
                    "$8 house wines and schooners",
                    "$12 cocktails"
                ])
            ),
            DealSource(
                venueId: venueId,
                url: "https://example.com/menu.pdf",
                type: .pdf,
                status: .approved
            ),
        ],
        forVenueId: venueId
    )

    return VenueDetailsView(
        viewModel: assembler.resolver.venueDetailsViewModel(googleID: venue.googleMapId)
    )
}

#Preview {
    venueDetailsPreview()
}
