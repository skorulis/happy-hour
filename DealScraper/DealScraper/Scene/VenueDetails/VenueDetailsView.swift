//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct VenueDetailsView: View {

    @State var viewModel: VenueDetailsViewModel
    var onVenueDeleted: (() -> Void)?
    @State private var selectedTab: VenueDetailsTab = .details
    @State private var showHeroImageURLPrompt = false
    @State private var heroImageURLString = ""
    @State private var showDeleteVenueConfirmation = false

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
        .alert("Hero Image URL", isPresented: $showHeroImageURLPrompt) {
            TextField("URL", text: $heroImageURLString)
            Button("Cancel", role: .cancel) {
                heroImageURLString = ""
            }
            Button("Save") {
                viewModel.setHeroImage(urlString: heroImageURLString)
                heroImageURLString = ""
            }
            .disabled(!isValidHeroImageURL(heroImageURLString))
        } message: {
            Text("Enter the URL for the hero image.")
        }
        .confirmationDialog(
            "Delete this venue?",
            isPresented: $showDeleteVenueConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Venue", role: .destructive) {
                if viewModel.deleteVenue() {
                    onVenueDeleted?()
                }
            }
        } message: {
            Text("This permanently removes the venue, all deal sources, and all deals. This cannot be undone.")
        }
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
        HStack(alignment: .top, spacing: 24) {
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
            .frame(maxWidth: .infinity, alignment: .leading)

            heroImageView(venue)
        }
    }

    @ViewBuilder
    private func heroImageView(_ venue: Venue) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        if let heroImageURL = venue.heroImage.flatMap({ URL(string: $0) }) {
            Link(destination: heroImageURL) {
                Color.clear
                    .aspectRatio(3 / 2, contentMode: .fill)
                    .frame(maxWidth: 200)
                    .overlay {
                        AsyncImage(url: heroImageURL) { phase in
                            switch phase {
                            case .empty:
                                heroImagePlaceholder
                                    .overlay { ProgressView() }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                heroImagePlaceholder
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .clipShape(shape)
            }
            .buttonStyle(.plain)
            .help("Open image in browser")
            .overlay(alignment: .topTrailing) {
                if viewModel.canClearHeroImage {
                    Button {
                        viewModel.clearHeroImage()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                }
            }
        } else {
            heroImagePlaceholder
                .aspectRatio(3 / 2, contentMode: .fit)
                .frame(maxWidth: 200)
                .overlay {
                    Button {
                        heroImageURLString = ""
                        showHeroImageURLPrompt = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
        }
    }

    private func isValidHeroImageURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            return false
        }
        return true
    }

    private var heroImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
                Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
            )
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
            LabeledContent("Last Crawl", value: viewModel.lastCrawlDescription)
            LabeledContent("Last Extraction", value: viewModel.lastExtractionDescription)

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
            Picker("Status", selection: Binding(
                get: { viewModel.venue?.status ?? .normal },
                set: { viewModel.setVenueStatus($0) }
            )) {
                Text("Normal").tag(VenueStatus.normal)
                Text("Broken").tag(VenueStatus.broken)
            }
            .pickerStyle(.segmented)

            LabeledContent("Google Place ID", value: venue.googleMapId)

            if !viewModel.types.isEmpty {
                LabeledContent("Types", value: viewModel.types.joined(separator: ", "))
            }

            Button("Delete Venue", role: .destructive) {
                showDeleteVenueConfirmation = true
            }
            .disabled(!viewModel.canDeleteVenue)

            if case let .failed(message) = viewModel.deleteVenueState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
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
            dealSourcesListSection
        }
    }

    @ViewBuilder
    private var dealSourcesListSection: some View {
        detailSection(title: "Deal Sources") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("URL", text: $viewModel.newDealSourceURLString)
                    .textFieldStyle(.roundedBorder)

                TextField("Source page (optional)", text: $viewModel.newDealSourcePageString)
                    .textFieldStyle(.roundedBorder)

                Button("Add Source") {
                    viewModel.addDealSource()
                }
                .disabled(!viewModel.canAddDealSource)

                switch viewModel.addDealSourceState {
                case .idle:
                    EmptyView()
                case .completed:
                    Text("Source added.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case let .failed(message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if viewModel.dealSources.isEmpty {
                    Text("No deal sources yet. Crawl the venue website from the Details tab or add a URL above.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.dealSources, id: \.url) { source in
                        DealSourceRow(
                            source: source,
                            onStatusChange: { status in
                                viewModel.setDealSourceStatus(source, status: status)
                            },
                            onDelete: {
                                viewModel.deleteDealSource(source)
                            }
                        )
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
                    DealRow(
                        item: item,
                        venueName: viewModel.venue?.name ?? "Unknown Venue",
                        onStatusChange: { status in
                            viewModel.setDealStatus(item, status: status)
                        },
                        onEdit: { draft in
                            viewModel.updateDeal(item, draft: draft)
                        },
                        onDuplicate: {
                            viewModel.duplicateDeal(item)
                        },
                        onDelete: {
                            viewModel.deleteDeal(item)
                        }
                    )
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
