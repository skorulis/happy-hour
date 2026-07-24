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

        #expect(stored.lastPathComponent == "abc123")
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

    @Test func rejectsFewerThanThreeWords() {
        #expect(!CrawlImageValidator.hasMinimumWords(""))
        #expect(!CrawlImageValidator.hasMinimumWords("Lunch"))
        #expect(!CrawlImageValidator.hasMinimumWords("Happy Hour"))
        #expect(CrawlImageValidator.wordCount(in: "Lunch") == 1)
        #expect(CrawlImageValidator.wordCount(in: "Happy Hour") == 2)
    }

    @Test func acceptsAtLeastThreeWords() {
        #expect(CrawlImageValidator.hasMinimumWords("Happy Hour Tuesday"))
        #expect(CrawlImageValidator.hasMinimumWords("Lunch\nSpecial\nFridays"))
        #expect(CrawlImageValidator.wordCount(in: "Happy Hour Tuesday") == 3)
        #expect(CrawlImageValidator.wordCount(in: "Lunch\nSpecial\nFridays") == 3)
    }

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

    @Test func rejectsSingleDateImage() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let fixtureURL = try fixtureImageURL(named: "mumbo_jumbos_tnt_dec16", extension: "jpeg")
        let url = URL(string: "https://mumbojumbos.com.au/wp-content/uploads/2025/11/TNT_DEC16_FB-1-2048x866.jpg")!
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

        #expect(!isRelevant)
    }

    @Test func rejectsBerryHotelDragBingoSingleDateImage() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let fixtureURL = try fixtureImageURL(named: "berry_hotel_drag_bingo", extension: "jpeg")
        let url = URL(string: "https://theberryhotel.com.au/wp-content/uploads/2026/06/Drag-Bingo-30th-July-Social-Tile-1-The-Berry-Hotel.jpg")!
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

        #expect(!isRelevant)
    }

    @Test func rejectsNthWeekdayOfMonthImage() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = CrawlImageCache(directory: directory)
        let fixtureURL = try fixtureImageURL(named: "azucar_latin_nights", extension: "webp")
        let url = URL(string: "https://cabravale.com.au/wp-content/uploads/2025/09/azucar-latin-nights.webp")!
        _ = try cache.store(
            data: Data(contentsOf: fixtureURL),
            hash: URLNormalizer.hash(url),
            fileExtension: "webp"
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

    private func fixtureImageURL(named name: String, extension ext: String = "jpeg") throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        let fallbackExtensions = ["jpeg", "jpg", "png", "webp"]
        for fallback in fallbackExtensions where fallback != ext {
            if let url = bundle.url(forResource: name, withExtension: fallback) {
                return url
            }
        }
        throw NSError(domain: "CrawlImageValidatorTests", code: 1)
    }
}
