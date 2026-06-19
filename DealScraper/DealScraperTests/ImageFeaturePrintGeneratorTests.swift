//Created by Alex Skorulis on 19/6/2026.

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import DealScraper

struct ImageFeaturePrintGeneratorTests {

    private let generator = ImageFeaturePrintGenerator()

    @Test func sameImageAtDifferentResolutionsAreSimilar() async throws {
        let sourceURL = try fixtureImageURL(named: "goat_deals")
        let resizedURL = try makeResizedCopy(of: sourceURL, width: 600, height: 800)

        let sourcePrint = try await generator.featurePrintData(for: sourceURL)
        let resizedPrint = try await generator.featurePrintData(for: resizedURL)

        let distance = try ImageFeaturePrintGenerator.distance(between: sourcePrint, and: resizedPrint)
        #expect(distance <= 0.35)
    }

    @Test func serializedFeaturePrintCanBeCompared() async throws {
        let sourceURL = try fixtureImageURL(named: "goat_deals")
        let featurePrint = try await generator.featurePrintData(for: sourceURL)

        let distance = try ImageFeaturePrintGenerator.distance(between: featurePrint, and: featurePrint)
        #expect(distance <= 0.35)
    }

    @Test func differentImagesAreNotSimilar() async throws {
        let sourceURL = try fixtureImageURL(named: "goat_deals")
        let otherURL = try makeSolidColorImage(width: 600, height: 800)

        let sourcePrint = try await generator.featurePrintData(for: sourceURL)
        let otherPrint = try await generator.featurePrintData(for: otherURL)

        let distance = try ImageFeaturePrintGenerator.distance(between: sourcePrint, and: otherPrint)
        #expect(distance > 0.35)
    }

    private func fixtureImageURL(named name: String) throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        let extensions = ["jpeg", "jpg", "png"]
        for ext in extensions {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        throw NSError(domain: "ImageFeaturePrintGeneratorTests", code: 1)
    }

    private func makeResizedCopy(of sourceURL: URL, width: Int, height: Int) throws -> URL {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let resizedImage = context.makeImage() else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpeg")
        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }
        CGImageDestinationAddImage(destination, resizedImage, nil)
        CGImageDestinationFinalize(destination)
        try (mutableData as Data).write(to: destinationURL)
        return destinationURL
    }

    private func makeSolidColorImage(width: Int, height: Int) throws -> URL {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else {
            throw ImageFeaturePrintGenerator.Error.invalidImage
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        try (mutableData as Data).write(to: destinationURL)
        return destinationURL
    }
}

private final class BundleToken {}
