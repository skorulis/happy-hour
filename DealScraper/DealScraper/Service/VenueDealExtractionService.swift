//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealExtractionServiceError: LocalizedError, Equatable {
    case missingVenueID
    case noApprovedSources
    case unsupportedProvider(VenueDealExtractionProvider)
    case missingAPIKey
    case missingModel

    var errorDescription: String? {
        switch self {
        case .missingVenueID:
            return "The venue must be saved before extracting deals."
        case .noApprovedSources:
            return "Approve at least one image or webpage deal source before extracting deals."
        case let .unsupportedProvider(provider):
            return "\(provider.rawValue) extraction is not available yet."
        case .missingAPIKey:
            return "Configure an API key in Settings."
        case .missingModel:
            return "Enter a model name."
        }
    }
}

@MainActor
final class VenueDealExtractionService {

    typealias ProgressHandler = @Sendable (String) -> Void

    private let dealSourceRepository: DealSourceRepository
    private let dealRepository: DealRepository
    private let materialPreparer: VenueDealSourceMaterialPreparer
    private let cursorExtractor: CursorVenueDealExtractor
    private let apiKeyStore: APIKeyStore

    init(
        dealSourceRepository: DealSourceRepository,
        dealRepository: DealRepository,
        materialPreparer: VenueDealSourceMaterialPreparer,
        cursorExtractor: CursorVenueDealExtractor,
        apiKeyStore: APIKeyStore
    ) {
        self.dealSourceRepository = dealSourceRepository
        self.dealRepository = dealRepository
        self.materialPreparer = materialPreparer
        self.cursorExtractor = cursorExtractor
        self.apiKeyStore = apiKeyStore
    }

    func extractDeals(
        for venue: Venue,
        provider: VenueDealExtractionProvider,
        model: String,
        onProgress: ProgressHandler? = nil
    ) async throws -> Int {
        guard let venueId = venue.id else {
            throw VenueDealExtractionServiceError.missingVenueID
        }

        let sources = try dealSourceRepository.findApproved(venueId: venueId)
        guard !sources.isEmpty else {
            throw VenueDealExtractionServiceError.noApprovedSources
        }

        let materials = try await materialPreparer.prepare(sources: sources) { message in
            onProgress?(message)
        }

        onProgress?("Analyzing with \(provider.rawValue)…")

        let payload = try await extractPayload(
            provider: provider,
            model: model,
            materials: materials,
            venueName: venue.name
        )

        let deals = VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: venueId,
            materials: materials
        )

        return try dealRepository.replaceAll(venueId: venueId, deals: deals)
    }

    func extractDealsFromDroppedImage(
        at url: URL,
        provider: VenueDealExtractionProvider,
        model: String,
        onProgress: ProgressHandler? = nil
    ) async throws -> [DealWithSchedules] {
        onProgress?("Preparing image…")

        let material = try materialPreparer.prepareLocalImage(at: url)
        let materials = [material]

        onProgress?("Analyzing with \(provider.rawValue)…")

        let payload = try await extractPayload(
            provider: provider,
            model: model,
            materials: materials,
            venueName: "Preview"
        )

        return VenueDealPersistenceMapper.map(
            payload: payload,
            venueId: 0,
            materials: materials
        )
    }

    private func extractPayload(
        provider: VenueDealExtractionProvider,
        model: String,
        materials: [VenueDealSourceMaterial],
        venueName: String
    ) async throws -> DealExtractionPayload {
        switch provider {
        case .cursor:
            let apiKey = apiKeyStore.cursorAPIKey
            guard !apiKey.isEmpty else {
                throw VenueDealExtractionServiceError.missingAPIKey
            }
            guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw VenueDealExtractionServiceError.missingModel
            }
            return try await cursorExtractor.extractDeals(
                materials: materials,
                venueName: venueName,
                instructions: VenueDealInstructions.multiSourceExtraction,
                apiKey: apiKey,
                model: model
            )
        case .openAI, .openRouter:
            throw VenueDealExtractionServiceError.unsupportedProvider(provider)
        }
    }
}
