//Created by Alex Skorulis on 18/6/2026.

import Foundation

enum VisionVenueDealExtractorError: LocalizedError, Sendable {
    case missingSourceText(DealSourceType)

    var errorDescription: String? {
        switch self {
        case let .missingSourceText(type):
            switch type {
            case .pdf:
                return "No text could be extracted from the PDF."
            case .image, .webpage:
                return nil
            }
        }
    }
}

enum VisionVenueDealExtractorSupport {
    nonisolated static func missingAPIKeyResult(
        materials: [VenueDealSourceMaterial],
        startTime: Date
    ) -> VenueDealExtractionResult {
        let message = "Configure an API key in Settings."
        let errors = materials.map {
            VenueDealSourceExtractionError(material: $0, message: message)
        }
        return VenueDealExtractionResult(
            extractions: [],
            errors: errors,
            duration: Date().timeIntervalSince(startTime)
        )
    }
}
