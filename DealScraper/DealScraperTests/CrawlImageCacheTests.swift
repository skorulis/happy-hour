//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import DealScraper

struct CrawlImageCacheTests {

    @Test func storeAndFindCachedFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)

        let data = Data("image-bytes".utf8)
        let stored = try cache.store(data: data, hash: "abc123", fileExtension: "jpg")

        #expect(stored.lastPathComponent == "abc123.jpg")
        #expect(try Data(contentsOf: stored) == data)

        let found = try #require(cache.findCachedFileURL(for: "abc123"))
        #expect(found == stored)
    }
}

@MainActor
struct CrawlImageFetcherTests {

    @Test func usesCacheWithoutDownloading() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let cachedData = Data("cached-image".utf8)
        _ = try cache.store(data: cachedData, hash: "cached-hash", fileExtension: "jpg")

        let fetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: FakeURLSession { _ in
                Issue.record("Should not download when cache exists")
                throw CrawlImageFetcherError.invalidResponse
            }
        )

        let localURL = try await fetcher.localFileURL(
            for: URL(string: "https://example.com/menu.jpg")!,
            hash: "cached-hash"
        )

        #expect(try Data(contentsOf: localURL) == cachedData)
    }

    @Test func downloadsAndCachesOnMiss() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let remoteData = Data("downloaded-image".utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/poster.png")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/png"]
        )!

        let fetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: FakeURLSession(data: remoteData, response: response)
        )

        let localURL = try await fetcher.localFileURL(
            for: URL(string: "https://example.com/poster.png")!,
            hash: "download-hash"
        )

        #expect(try Data(contentsOf: localURL) == remoteData)
        #expect(cache.findCachedFileURL(for: "download-hash") == localURL)

        let cachedOnlyFetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: FakeURLSession { _ in
                Issue.record("Second fetch should use cache")
                throw CrawlImageFetcherError.invalidResponse
            }
        )

        let cachedURL = try await cachedOnlyFetcher.localFileURL(
            for: URL(string: "https://example.com/poster.png")!,
            hash: "download-hash"
        )
        #expect(cachedURL == localURL)
    }
}

private final class BundleToken {}

@MainActor
struct CrawlImageValidatorTests {

    @Test func acceptsImageWithText() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let fixtureURL = try fixtureImageURL(named: "hive_bar_happy_hour")
        let url = URL(string: "https://example.com/hive_bar_happy_hour.jpeg")!
        _ = try cache.store(
            data: Data(contentsOf: fixtureURL),
            hash: URLNormalizer.hash(url),
            fileExtension: "jpeg"
        )

        let validator = CrawlImageValidator(
            fetcher: CrawlImageFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlImageFetcherError.invalidResponse
                }
            ),
            imageExtractor: DealImageExtractor(),
            featurePrintGenerator: ImageFeaturePrintGenerator()
        )

        let isRelevant = await validator.validateImage(url: url) != nil

        #expect(isRelevant)
    }

    @Test func rejectsImageWithoutText() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let url = URL(string: "https://example.com/blank.png")!
        _ = try cache.store(data: Self.largeBlankPNGData, hash: URLNormalizer.hash(url), fileExtension: "png")

        let validator = CrawlImageValidator(
            fetcher: CrawlImageFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlImageFetcherError.invalidResponse
                }
            ),
            imageExtractor: DealImageExtractor(),
            featurePrintGenerator: ImageFeaturePrintGenerator()
        )

        let isRelevant = await validator.validateImage(url: url) != nil

        #expect(!isRelevant)
    }

    @Test func rejectsImageBelowMinimumDimensions() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let url = URL(string: "https://example.com/small-icon.png")!
        _ = try cache.store(data: Self.smallPNGData, hash: URLNormalizer.hash(url), fileExtension: "png")

        let validator = CrawlImageValidator(
            fetcher: CrawlImageFetcher(
                cache: cache,
                urlSession: FakeURLSession { _ in
                    throw CrawlImageFetcherError.invalidResponse
                }
            ),
            imageExtractor: DealImageExtractor(),
            featurePrintGenerator: ImageFeaturePrintGenerator()
        )

        let isRelevant = await validator.validateImage(url: url) != nil

        #expect(!isRelevant)
    }

    private static let largeBlankPNGData: Data = pngData(width: 600, height: 600)

    private static let smallPNGData: Data = pngData(width: 400, height: 400)

    private static func pngData(width: Int, height: Int) -> Data {
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
        let image = context.makeImage()!
        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else {
            fatalError("Failed to create image destination")
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }

    private func fixtureImageURL(named name: String) throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        let extensions = ["jpeg", "jpg", "png"]
        for ext in extensions {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        throw NSError(domain: "CrawlImageValidatorTests", code: 1)
    }
}
