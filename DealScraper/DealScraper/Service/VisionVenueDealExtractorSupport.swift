//Created by Alex Skorulis on 18/6/2026.

import Foundation

enum VisionVenueDealExtractorError: LocalizedError, Sendable {
    case unsupportedSourceType(DealSourceType)
    case missingSourceText(DealSourceType)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSourceType(type):
            switch type {
            case .webpage:
                return "Vision model extraction only supports image sources. Webpage sources are not supported."
            case .pdf:
                return "Vision model extraction does not support PDF sources."
            case .image:
                return nil
            }
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
    nonisolated static func imageReference(
        for material: VenueDealSourceMaterial
    ) -> VisionDealAPI.ImageReference {
        if let pngData = material.pngData {
            return .base64(data: pngData.base64EncodedString(), mimeType: "image/png")
        }
        return .url(material.url.absoluteString)
    }

    nonisolated static func perSourceInstructions(
        venueName: String,
        material: VenueDealSourceMaterial
    ) -> String {
        let instructions = VenueDealInstructions.dealExtraction(for: material)
        let preamble = VenueDealInstructions.promptPreamble(
            venueName: venueName,
            material: material
        )
        return """
        \(instructions)

        \(preamble)
        """
    }

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
