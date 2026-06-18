//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionServiceError: LocalizedError, Equatable {
    case missingVenueID
    case noApprovedSources
    case unsupportedProvider(VenueDealExtractionProvider)
    case missingModel
    case extractionFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .missingVenueID:
            return "The venue must be saved before extracting deals."
        case .noApprovedSources:
            return "Approve at least one image or webpage deal source before extracting deals."
        case let .unsupportedProvider(provider):
            return "\(provider.rawValue) extraction is not available yet."
        case .missingModel:
            return "Enter a model name."
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
        model: String,
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

        await progress("Analyzing with \(provider.rawValue)…")

        let result = try await extractPayload(
            provider: provider,
            model: model,
            materials: materials,
            venueName: venue.name
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
        model: String,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        await progress("Preparing image…")

        let material = try materialPreparer.prepareLocalImage(at: url)
        let materials = [material]

        await progress("Analyzing with \(provider.rawValue)…")

        let result = try await extractPayload(
            provider: provider,
            model: model,
            materials: materials,
            venueName: "Preview"
        )

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: 0)
        let deals = DealCondenser().condense(mapped)
        await progress.completed(results: deals)
        return deals
    }

    func extractDealsFromRemoteURL(
        at url: URL,
        provider: VenueDealExtractionProvider,
        model: String,
        progress: ProgressMonitor<[DealWithSchedules]> = .empty
    ) async throws -> [DealWithSchedules] {
        if VenueDealSourceMaterialPreparer.isImageURL(url) {
            await progress("Analyzing with \(provider.rawValue)…")
        } else {
            await progress("Preparing source…")
        }

        let material = materialPreparer.prepareRemoteURL(at: url)
        let materials = [material]

        await progress("Analyzing with \(provider.rawValue)…")

        let result = try await extractPayload(
            provider: provider,
            model: model,
            materials: materials,
            venueName: "Preview"
        )

        let mapped = VenueDealPersistenceMapper.map(sourced: result.extractions, venueId: 0)
        let deals = DealCondenser().condense(mapped)
        await progress.completed(results: deals)
        return deals
    }

    private func extractPayload(
        provider: VenueDealExtractionProvider,
        model: String,
        materials: [VenueDealSourceMaterial],
        venueName: String
    ) async throws -> VenueDealExtractionResult {
        let result: VenueDealExtractionResult
        switch provider {
        case .openAI:
            let resolvedModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "gpt-4o"
                : model
            result = await openAIExtractor.extractDeals(
                materials: materials,
                venueName: venueName,
                model: resolvedModel
            )
        case .openRouter:
            guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw VenueDealExtractionServiceError.missingModel
            }
            result = await openRouterExtractor.extractDeals(
                materials: materials,
                venueName: venueName,
                model: model
            )
        }

        if let message = result.failureMessage {
            throw VenueDealExtractionServiceError.extractionFailed(message: message)
        }

        return result
    }
}
