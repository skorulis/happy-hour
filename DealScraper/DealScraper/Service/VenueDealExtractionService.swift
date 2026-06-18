//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionServiceError: LocalizedError, Equatable {
    case missingVenueID
    case noApprovedSources
    case unsupportedProvider(VenueDealExtractionProvider)
    case extractionFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .missingVenueID:
            return "The venue must be saved before extracting deals."
        case .noApprovedSources:
            return "Approve at least one image or webpage deal source before extracting deals."
        case let .unsupportedProvider(provider):
            return "\(provider.rawValue) extraction is not available yet."
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
    private let openAIExtractor: OpenAIVenueDealExtractor
    private let openRouterExtractor: OpenRouterVenueDealExtractor

    init(
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        materialPreparer: VenueDealSourceMaterialPreparer,
        openAIExtractor: OpenAIVenueDealExtractor,
        openRouterExtractor: OpenRouterVenueDealExtractor
    ) {
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.materialPreparer = materialPreparer
        self.openAIExtractor = openAIExtractor
        self.openRouterExtractor = openRouterExtractor
    }

    func extractDeals(
        for venue: Venue,
        provider: VenueDealExtractionProvider,
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

        let result = try await extractPayload(
            provider: provider,
            materials: materials,
            venueName: venue.name,
            progress: progress
        )

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: venueId)
        let deals = DealCondenser().condense(mapped)
        let savedCount = try dealRepository.replaceAll(venueId: venueId, deals: deals)

        let results = VenueDealExtractionResults(
            dealsFound: savedCount,
            duration: result.duration,
            errorCount: result.errors.count
        )
        await progress.completed(results: results)
        return results
    }

    func extractDealsFromDroppedImage(
        at url: URL,
        provider: VenueDealExtractionProvider,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        await progress("Preparing image…")

        let material = try materialPreparer.prepareLocalImage(at: url)
        let materials = [material]

        let result = try await extractPayload(
            provider: provider,
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
        provider: VenueDealExtractionProvider,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        if VenueDealSourceMaterialPreparer.isImageURL(url) {
            await progress("Analyzing with \(provider.rawValue)…")
        } else {
            await progress("Preparing source…")
        }

        let material = materialPreparer.prepareRemoteURL(at: url)
        let materials = [material]

        let result = try await extractPayload(
            provider: provider,
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
        provider: VenueDealExtractionProvider,
        materials: [VenueDealSourceMaterial],
        venueName: String,
        progress: ProgressMonitor<Result>
    ) async throws -> VenueDealExtractionResult {
        let result: VenueDealExtractionResult
        switch provider {
        case .openAI:
            result = await openAIExtractor.extractDeals(
                materials: materials,
                venueName: venueName,
                progress: progress
            )
        case .openRouter:
            result = await openRouterExtractor.extractDeals(
                materials: materials,
                venueName: venueName,
                progress: progress
            )
        }

        if let message = result.failureMessage {
            throw VenueDealExtractionServiceError.extractionFailed(message: message)
        }

        return result
    }
}
