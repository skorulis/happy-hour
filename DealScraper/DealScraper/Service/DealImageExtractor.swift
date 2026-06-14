//  Created by Alexander Skorulis on 14/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Vision

struct DealImageExtractor {

    enum Error: Swift.Error {
        case invalidImage
        case recognitionFailed
    }

    nonisolated func extractTexts(from url: URL) async throws -> [String] {
        guard let cgImage = Self.loadCGImage(from: url) else {
            throw Error.invalidImage
        }
        return try await extractTexts(from: cgImage)
    }

    nonisolated func extractTexts(from cgImage: CGImage) async throws -> [String] {
        try await Task.detached {
            try Self.performRecognition(on: cgImage)
        }.value
    }

    private nonisolated static func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private nonisolated static func performRecognition(on cgImage: CGImage) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-AU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw Error.recognitionFailed
        }

        guard let observations = request.results else {
            return []
        }

        let sortedObservations = observations.sorted { lhs, rhs in
            let leftY = lhs.boundingBox.origin.y
            let rightY = rhs.boundingBox.origin.y
            if leftY != rightY {
                return leftY > rightY
            }
            return lhs.boundingBox.origin.x < rhs.boundingBox.origin.x
        }

        return sortedObservations.compactMap { observation in
            let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text, !text.isEmpty else { return nil }
            return text
        }
    }
}
