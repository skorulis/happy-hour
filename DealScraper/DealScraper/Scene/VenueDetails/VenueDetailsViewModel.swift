//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueDetailsViewModel {

    enum DeleteSourcesState: Equatable {
        case idle
        case completed(deleted: Int)
        case failed(message: String)
    }

    enum DeleteDealsState: Equatable {
        case idle
        case completed(deleted: Int)
        case failed(message: String)
    }

    enum ExtractionState: Equatable {
        case idle
        case extracting(progress: String)
        case completed(VenueDealExtractionResults)
        case failed(message: String)
    }

    enum AddDealSourceState: Equatable {
        case idle
        case completed
        case failed(message: String)
    }

    enum DeleteVenueState: Equatable {
        case idle
        case failed(message: String)
    }

    enum GenerateBlurbState: Equatable {
        case idle
        case generating
        case failed(message: String)
    }

    enum SaveBlurbState: Equatable {
        case idle
        case completed
        case failed(message: String)
    }

    let googleMapId: String
    private(set) var venue: Venue?
    private(set) var venueLinks: VenueLinks?
    private(set) var dealSources: [DealSource] = []
    private(set) var deals: [DealWithSchedules] = []
    private(set) var deleteSourcesState: DeleteSourcesState = .idle
    private(set) var deleteDealsState: DeleteDealsState = .idle
    private(set) var addDealSourceState: AddDealSourceState = .idle
    private(set) var deleteVenueState: DeleteVenueState = .idle
    private(set) var generateBlurbState: GenerateBlurbState = .idle
    private(set) var saveBlurbState: SaveBlurbState = .idle

    var newDealSourceURLString = ""
    var newDealSourcePageString = ""
    var blurbText = "" {
        didSet {
            if saveBlurbState == .completed {
                saveBlurbState = .idle
            }
        }
    }

    var openRouterModel: String = LLMModelStore.defaultOpenRouterModel {
        didSet { llmModelStore.openRouterModel = openRouterModel }
    }

    private let venueRepository: VenueRepository
    private let suburbRepository: SuburbRepository
    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let venueLinksRepository: VenueLinksRepository
    private let heroImageStore: VenueHeroImageStore
    private let jobQueue: JobQueue
    private let llmModelStore: LLMModelStore
    private let venueBlurbGenerator: VenueBlurbGenerator

    @Resolvable<Resolver>
    init(
        @Argument googleMapId: String,
        venueRepository: VenueRepository,
        suburbRepository: SuburbRepository,
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        venueLinksRepository: VenueLinksRepository,
        heroImageStore: VenueHeroImageStore,
        jobQueue: JobQueue,
        llmModelStore: LLMModelStore,
        venueBlurbGenerator: VenueBlurbGenerator
    ) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        self.suburbRepository = suburbRepository
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.venueLinksRepository = venueLinksRepository
        self.heroImageStore = heroImageStore
        self.jobQueue = jobQueue
        self.llmModelStore = llmModelStore
        self.venueBlurbGenerator = venueBlurbGenerator
        openRouterModel = llmModelStore.openRouterModel
        load()
    }

    var crawlState: ProgressState<VenueCrawlResults> {
        guard let venueId = venue?.id else { return .idle }
        guard let job = jobQueue.latestJob(venueId: venueId, type: .crawlWebsite) else { return .idle }
        return mapCrawlState(job.status)
    }

    var extractionState: ExtractionState {
        guard let venueId = venue?.id else { return .idle }
        guard let job = jobQueue.latestJob(venueId: venueId, type: .extractDeals) else { return .idle }
        return mapExtractionState(job.status)
    }

    var venueJobs: [JobItem] {
        guard let venueId = venue?.id else { return [] }
        return jobQueue.jobs(for: venueId)
    }

    var canCrawl: Bool {
        venue?.websiteUri != nil && !isCrawling
    }

    var canDeleteSources: Bool {
        venue?.id != nil && !isCrawling
    }

    var isCrawling: Bool {
        guard let venueId = venue?.id else { return false }
        return jobQueue.isJobActive(venueId: venueId, type: .crawlWebsite)
    }

    var isExtracting: Bool {
        guard let venueId = venue?.id else { return false }
        return jobQueue.isJobActive(venueId: venueId, type: .extractDeals)
    }

    var approvedSourceCount: Int {
        dealSources.filter { $0.status == .approved }.count
    }

    var canExtractDeals: Bool {
        venue?.id != nil && approvedSourceCount > 0 && !isExtracting && !isCrawling
    }

    var canDeleteDeals: Bool {
        venue?.id != nil && !isExtracting && !isCrawling
    }

    var canDeleteVenue: Bool {
        venue?.id != nil && !isExtracting && !isCrawling
    }

    var canAddDealSource: Bool {
        venue?.id != nil && resolveDealSourceURL(newDealSourceURLString) != nil && !isCrawling
    }

    var canClearHeroImage: Bool {
        guard let venue, venue.id != nil else { return false }
        return venue.heroImage?.isEmpty == false
    }

    var suburbName: String? {
        if let suburbId = venue?.suburbId,
           let suburb = try? suburbRepository.find(id: suburbId)
        {
            return suburb.name
        }
        if let address = formattedAddress,
           let parsed = AustraliaAddressParser.parse(from: address)
        {
            return parsed.suburb
        }
        return nil
    }

    var canGenerateBlurb: Bool {
        venue?.id != nil && suburbName != nil && generateBlurbState != .generating
    }

    var canSaveBlurb: Bool {
        guard venue?.id != nil, generateBlurbState != .generating else { return false }
        let draft = blurbText.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = venue?.blurb?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return draft != saved
    }

    func generateBlurb() async {
        guard let venue, let venueId = venue.id, let suburb = suburbName else { return }
        guard let website = venue.websiteUri else { return }

        generateBlurbState = .generating

        do {
            let blurb = try await venueBlurbGenerator.generateBlurb(
                pubName: venue.name,
                website: website,
                suburb: suburb
            )
            try venueRepository.updateBlurb(venueId: venueId, blurb: blurb)
            load()
            generateBlurbState = .idle
        } catch {
            generateBlurbState = .failed(message: error.localizedDescription)
        }
    }

    func saveBlurb() {
        guard let venueId = venue?.id, canSaveBlurb else { return }

        let trimmed = blurbText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try venueRepository.updateBlurb(venueId: venueId, blurb: trimmed)
            load()
            saveBlurbState = .completed
        } catch {
            saveBlurbState = .failed(message: error.localizedDescription)
        }
    }

    func clearHeroImage() {
        guard let venueId = venue?.id, canClearHeroImage else { return }

        do {
            try heroImageStore.clearHeroImage(venueId: venueId)
            load()
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setHeroImage(urlString: String) async {
        guard let venueId = venue?.id else { return }

        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              url.scheme != nil
        else {
            return
        }

        do {
            try await heroImageStore.setHeroImage(venueId: venueId, remoteURL: url)
            load()
        } catch {
            print("Failed to set venue hero image: \(error.localizedDescription)")
        }
    }

    func crawlWebsite() {
        guard let venueId = venue?.id, canCrawl else { return }

        jobQueue.enqueue(venueId: venueId, type: .crawlWebsite) { [weak self] in
            self?.load()
        }
    }

    func deleteSources() {
        guard let venueId = venue?.id, canDeleteSources else { return }

        do {
            let deleted = try dealSourceRepository.deleteAll(venueId: venueId)
            deleteSourcesState = .completed(deleted: deleted)
            jobQueue.clearCompleted(for: venueId, type: .crawlWebsite)
            load()
        } catch {
            deleteSourcesState = .failed(message: error.localizedDescription)
        }
    }

    func extractDeals() {
        guard let venueId = venue?.id, canExtractDeals else { return }

        jobQueue.enqueue(venueId: venueId, type: .extractDeals) { [weak self] in
            self?.load()
        }
    }

    func deleteDeals() {
        guard let venueId = venue?.id, canDeleteDeals else { return }

        do {
            let deleted = try dealRepository.deleteAll(venueId: venueId)
            deleteDealsState = .completed(deleted: deleted)
            jobQueue.clearCompleted(for: venueId, type: .extractDeals)
            load()
        } catch {
            deleteDealsState = .failed(message: error.localizedDescription)
        }
    }

    func addDealSource() {
        guard let venueId = venue?.id else { return }

        guard let url = resolveDealSourceURL(newDealSourceURLString) else {
            addDealSourceState = .failed(message: "Please enter a valid URL.")
            return
        }

        let type = PageLinkFilter.sourceType(for: url)

        let trimmedSource = newDealSourcePageString.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceURLString: String
        if !trimmedSource.isEmpty {
            guard let resolvedSource = resolveURLString(trimmedSource) else {
                addDealSourceState = .failed(message: "Please enter a valid source URL.")
                return
            }
            sourceURLString = resolvedSource.absoluteString
        } else if type == .image || type == .pdf {
            sourceURLString = defaultSourcePageURL(for: url)
        } else {
            sourceURLString = url.absoluteString
        }

        let source = DealSource(
            venueId: venueId,
            url: url.absoluteString,
            sourceURL: sourceURLString,
            type: type,
            status: .approved,
            date: .now
        )

        do {
            _ = try dealSourceRepository.upsert(sources: [source], forVenueId: venueId)
            newDealSourceURLString = ""
            newDealSourcePageString = ""
            addDealSourceState = .completed
            load()
        } catch {
            addDealSourceState = .failed(message: error.localizedDescription)
        }
    }

    func setDealSourceStatus(_ source: DealSource, status: DealStatus) {
        guard let id = source.id else { return }

        do {
            try dealSourceRepository.updateStatus(id: id, status: status)
            if let index = dealSources.firstIndex(where: { $0.id == id }) {
                dealSources[index].status = status
            }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func deleteDealSource(_ source: DealSource) {
        guard let id = source.id, venue?.id != nil, !isCrawling else { return }

        do {
            guard try dealSourceRepository.delete(id: id) else { return }
            dealSources.removeAll { $0.id == id }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setDealStatus(_ item: DealWithSchedules, status: DealStatus) {
        guard let id = item.deal.id else { return }

        do {
            try dealRepository.updateStatus(id: id, status: status)
            if let index = deals.firstIndex(where: { $0.deal.id == id }) {
                var updated = deals[index]
                updated.deal.status = status
                deals[index] = updated
            }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func duplicateDeal(_ item: DealWithSchedules) {
        guard let id = item.deal.id else { return }

        do {
            guard let duplicated = try dealRepository.duplicate(id: id) else { return }
            deals.append(duplicated)
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func deleteDeal(_ item: DealWithSchedules) {
        guard let id = item.deal.id, canDeleteDeals else { return }

        do {
            guard try dealRepository.delete(id: id) else { return }
            deals.removeAll { $0.deal.id == id }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func updateDeal(_ item: DealWithSchedules, draft: EditDealDraft, status: DealStatus = .approved) {
        guard let id = item.deal.id else { return }

        do {
            try dealRepository.update(
                id: id,
                title: draft.title.isEmpty ? nil : draft.title,
                details: draft.details.isEmpty ? nil : draft.details,
                conditions: draft.conditions.isEmpty ? nil : draft.conditions,
                sourceURL: draft.sourceURL.isEmpty ? nil : draft.sourceURL,
                creativeURL: draft.creativeURL.isEmpty ? nil : draft.creativeURL,
                startDate: draft.startDate,
                endDate: draft.endDate,
                schedules: draft.schedules.map { $0.toDealSchedule() },
                status: status
            )
            if let index = deals.firstIndex(where: { $0.deal.id == id }) {
                var updatedDeal = deals[index].deal
                updatedDeal.title = draft.title.isEmpty ? nil : draft.title
                updatedDeal.details = draft.details.isEmpty ? nil : draft.details
                updatedDeal.conditions = draft.conditions.isEmpty ? nil : draft.conditions
                updatedDeal.sourceURL = draft.sourceURL.isEmpty ? nil : draft.sourceURL
                updatedDeal.creativeURL = draft.creativeURL.isEmpty ? nil : draft.creativeURL
                updatedDeal.startDate = draft.startDate
                updatedDeal.endDate = draft.endDate
                updatedDeal.status = status
                updatedDeal.updateDate = .now
                deals[index] = DealWithSchedules(
                    deal: updatedDeal,
                    schedules: draft.schedules.map { $0.toDealSchedule() }
                )
            }
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    func setVenueStatus(_ status: VenueStatus) {
        guard let venueId = venue?.id else { return }

        do {
            try venueRepository.updateStatus(venueId: venueId, status: status)
            venue?.status = status
        } catch {
            // Keep the current UI state if persistence fails.
        }
    }

    @discardableResult
    func deleteVenue() -> Bool {
        guard let venueId = venue?.id, canDeleteVenue else { return false }

        do {
            jobQueue.clearAll(for: venueId)
            try heroImageStore.deleteStoredImage(for: venueId)
            guard try venueRepository.delete(id: venueId) else {
                deleteVenueState = .failed(message: "Venue not found.")
                return false
            }
            venue = nil
            venueLinks = nil
            dealSources = []
            deals = []
            deleteVenueState = .idle
            return true
        } catch {
            deleteVenueState = .failed(message: error.localizedDescription)
            return false
        }
    }

    private func load() {
        venue = try? venueRepository.find(googleMapId: googleMapId)
        if let venueId = venue?.id {
            venueLinks = try? venueLinksRepository.find(venueId: venueId)
            dealSources = (try? dealSourceRepository.find(venueId: venueId)) ?? []
            deals = (try? dealRepository.find(venueId: venueId)) ?? []
        } else {
            venueLinks = nil
            dealSources = []
            deals = []
        }
        blurbText = venue?.blurb ?? ""
        saveBlurbState = .idle
    }

    private func mapCrawlState(_ status: JobStatus) -> ProgressState<VenueCrawlResults> {
        switch status {
        case .pending:
            return .inProgress(progress: "Queued…")
        case let .running(progress):
            return .inProgress(progress: progress)
        case let .completed(.crawl(results)):
            return .completed(results)
        case let .failed(message):
            return .failed(message: message)
        case .cancelled:
            return .idle
        case .completed:
            return .idle
        }
    }

    private func mapExtractionState(_ status: JobStatus) -> ExtractionState {
        switch status {
        case .pending:
            return .extracting(progress: "Queued…")
        case let .running(progress):
            return .extracting(progress: progress)
        case let .completed(.extract(results)):
            return .completed(results)
        case let .failed(message):
            return .failed(message: message)
        case .cancelled:
            return .idle
        case .completed:
            return .idle
        }
    }

    var googlePlace: GooglePlace? {
        guard let venue, let data = venue.json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GooglePlace.self, from: data)
    }

    var formattedAddress: String? {
        googlePlace?.formattedAddress
    }

    var types: [String] {
        googlePlace?.types ?? []
    }

    var coordinateDescription: String? {
        guard let venue else { return nil }
        return String(format: "%.6f, %.6f", venue.lat, venue.lng)
    }

    var lastCrawlDescription: String {
        guard let lastCrawl = venue?.lastCrawlDate else { return "Never" }
        return lastCrawl.formatted(date: .abbreviated, time: .shortened)
    }

    var lastExtractionDescription: String {
        guard let lastExtraction = venue?.lastExtractionDate else { return "Never" }
        return lastExtraction.formatted(date: .abbreviated, time: .shortened)
    }

    var mapsURL: URL? {
        guard let venue else { return nil }
        let placeId = venue.googleMapId.hasPrefix("places/")
            ? String(venue.googleMapId.dropFirst("places/".count))
            : venue.googleMapId
        var components = URLComponents(string: "https://www.google.com/maps/search/")!
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: venue.name),
            URLQueryItem(name: "query_place_id", value: placeId),
        ]
        return components.url
    }

    private func defaultSourcePageURL(for contentURL: URL) -> String {
        if let whatsOn = venueLinks?.whatsOn,
           !whatsOn.isEmpty,
           resolveURLString(whatsOn) != nil
        {
            return whatsOn
        }
        if let website = venue?.websiteUri,
           !website.isEmpty,
           resolveURLString(website) != nil
        {
            return website
        }
        return contentURL.absoluteString
    }

    private func resolveDealSourceURL(_ string: String) -> URL? {
        resolveURLString(string)
    }

    private func resolveURLString(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return URLNormalizer.normalize(url) ?? url
        }

        guard let baseURL = baseURLForRelativeLinks else { return nil }
        return URLNormalizer.resolve(trimmed, relativeTo: baseURL)
    }

    private var baseURLForRelativeLinks: URL? {
        if let website = venue?.websiteUri,
           let url = URL(string: website)
        {
            return URLNormalizer.normalize(url) ?? url
        }
        if let whatsOn = venueLinks?.whatsOn,
           let url = URL(string: whatsOn)
        {
            return URLNormalizer.normalize(url) ?? url
        }
        return nil
    }
}
