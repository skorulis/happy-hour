//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionServiceError: LocalizedError, Equatable {
    case missingVenueID
    case noApprovedSources
    case extractionFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .missingVenueID:
            return "The venue must be saved before extracting deals."
        case .noApprovedSources:
            return "Approve at least one image, webpage, or PDF deal source before extracting deals."
        case let .extractionFailed(message):
            return message
        }
    }
}

@MainActor
final class VenueDealExtractionService {

    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let materialPreparer: VenueDealSourceMaterialPreparer
    private let extractor: OpenRouterVenueDealExtractor

    init(
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        materialPreparer: VenueDealSourceMaterialPreparer,
        extractor: OpenRouterVenueDealExtractor
    ) {
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.materialPreparer = materialPreparer
        self.extractor = extractor
    }

    func extractDeals(
        for venue: Venue,
        progress: ProgressMonitor<VenueDealExtractionResults> = .empty
    ) async throws -> VenueDealExtractionResults {
        guard let venueId = venue.id else {
            throw VenueDealExtractionServiceError.missingVenueID
        }

        let sources = try dealSourceRepository.findApproved(venueId: venueId)
        guard !sources.isEmpty else {
            throw VenueDealExtractionServiceError.noApprovedSources
        }

        let materials = try await materialPreparer.prepare(sources: sources, progress: progress)

        try Task.checkCancellation()

        let result = try await extractPayload(
            materials: materials,
            venueName: venue.name,
            progress: progress
        )

        try Task.checkCancellation()

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: venueId)
        let deals = mapped // DealCondenser().condense(mapped)
        let savedCount = try dealRepository.replaceAll(venueId: venueId, deals: deals)

        let results = VenueDealExtractionResults(
            dealsFoundBeforeCondensing: mapped.count,
            dealsFound: savedCount,
            duration: result.duration,
            errorCount: result.errors.count
        )
        await progress.completed(results: results)
        return results
    }

    func extractDealsFromDroppedImage(
        at url: URL,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        await progress("Preparing image…")

        let material = try materialPreparer.prepareLocalImage(at: url)
        let materials = [material]

        let result = try await extractPayload(
            materials: materials,
            venueName: "Preview",
            progress: progress
        )

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: 0)
        let deals = DealCondenser().condense(mapped)
        await progress.completed(results: deals)
        return deals
    }

    func extractDealsFromRemoteURL(
        at url: URL,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        let material: VenueDealSourceMaterial
        switch PageLinkFilter.sourceType(for: url) {
        case .image:
            await progress("Analyzing image")
            material = materialPreparer.prepareRemoteURL(at: url)
        case .webpage:
            await progress("Loading webpage…")
            material = try await materialPreparer.prepareWebpage(at: url)
        case .pdf:
            await progress("Extracting PDF text…")
            material = try await materialPreparer.preparePDF(at: url)
        }
        
        let materials = [material]

        let result = try await extractPayload(
            materials: materials,
            venueName: "Preview",
            progress: progress
        )

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: 0)
        let deals = DealCondenser().condense(mapped)
        await progress.completed(results: deals)
        return deals
    }

    private func extractPayload<Result>(
        materials: [VenueDealSourceMaterial],
        venueName: String,
        progress: ProgressMonitor<Result>
    ) async throws -> VenueDealExtractionResult {
        let result = await extractor.extractDeals(
            materials: materials,
            venueName: venueName,
            progress: progress
        )

        if let message = result.failureMessage {
            throw VenueDealExtractionServiceError.extractionFailed(message: message)
        }

        return result
    }
}
