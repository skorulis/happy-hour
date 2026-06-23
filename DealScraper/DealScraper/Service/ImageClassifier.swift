//Created by Alex Skorulis on 24/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Vision

nonisolated struct ImageClassifier: Sendable {

    private static let buildingKeywords = [
        "building",
        "structure",
        "architecture",
        "house",
        "facade",
        "skyscraper",
    ]

    static func isBuildingRelatedIdentifier(_ identifier: String) -> Bool {
        let lower = identifier.lowercased()
        return buildingKeywords.contains { lower.contains($0) }
    }

    static func buildingScore(from observations: [VNClassificationObservation]) -> CGFloat {
        buildingScore(
            from: observations.map { (identifier: $0.identifier, confidence: $0.confidence) }
        )
    }

    static func buildingScore(from classifications: [(identifier: String, confidence: Float)]) -> CGFloat {
        let matching = classifications.filter { isBuildingRelatedIdentifier($0.identifier) }
        return CGFloat(matching.map(\.confidence).max() ?? 0)
    }

    nonisolated func buildingScore(for localURL: URL) async throws -> CGFloat {
        try await Task.detached {
            try Self.classifyBuildingScore(from: localURL)
        }.value
    }

    private nonisolated static func classifyBuildingScore(from localURL: URL) throws -> CGFloat {
        guard let cgImage = loadCGImage(from: localURL) else {
            return 0
        }
        return try classifyBuildingScore(from: cgImage)
    }

    private nonisolated static func classifyBuildingScore(from cgImage: CGImage) throws -> CGFloat {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let observations = request.results else {
            return 0
        }
        return buildingScore(from: observations)
    }

    private nonisolated static func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
