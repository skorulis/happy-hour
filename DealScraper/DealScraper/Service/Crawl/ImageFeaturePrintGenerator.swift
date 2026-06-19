//Created by Alex Skorulis on 19/6/2026.

import Foundation
import ImageIO
import Vision

nonisolated struct ImageFeaturePrintGenerator: Sendable {

    enum Error: Swift.Error {
        case invalidImage
        case featurePrintFailed
        case invalidSerializedFeaturePrint
        case distanceComputationFailed
    }

    nonisolated func featurePrintData(for localURL: URL) async throws -> Data {
        try await Task.detached {
            try Self.generateFeaturePrintData(from: localURL)
        }.value
    }

    nonisolated static func generateFeaturePrintData(from localURL: URL) throws -> Data {
        guard let cgImage = loadCGImage(from: localURL) else {
            throw Error.invalidImage
        }
        return try generateFeaturePrintData(from: cgImage)
    }

    nonisolated static func generateFeaturePrintData(from cgImage: CGImage) throws -> Data {
        let request = VNGenerateImageFeaturePrintRequest()
        request.revision = VNGenerateImageFeaturePrintRequestRevision2
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            throw Error.featurePrintFailed
        }
        return try serialize(observation)
    }

    nonisolated static func distance(between a: Data, and b: Data) throws -> Float {
        let observationA = try deserialize(a)
        let observationB = try deserialize(b)
        var distance: Float = 0
        do {
            try observationA.computeDistance(&distance, to: observationB)
        } catch {
            throw Error.distanceComputationFailed
        }
        return distance
    }

    nonisolated static func areSimilar(_ a: Data, _ b: Data, threshold: Float) -> Bool {
        guard let distance = try? distance(between: a, and: b) else {
            return false
        }
        return distance <= threshold
    }

    private nonisolated static func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private nonisolated static func serialize(_ observation: VNFeaturePrintObservation) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }

    private nonisolated static func deserialize(_ data: Data) throws -> VNFeaturePrintObservation {
        guard let observation = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: VNFeaturePrintObservation.self,
            from: data
        ) else {
            throw Error.invalidSerializedFeaturePrint
        }
        return observation
    }
}
