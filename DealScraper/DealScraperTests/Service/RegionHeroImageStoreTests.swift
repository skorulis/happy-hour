//Created by Alexander Skorulis on 23/7/2026.

import ASKCore
import Foundation
import GRDB
import Testing
@testable import DealScraper

@MainActor
struct RegionHeroImageStoreTests {

    /// 1x1 PNG (optimizer re-encodes to JPEG for R2)
    private static let sampleImage = Data(
        base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    )!

    @MainActor
    final class FakeHeroUploader: HeroImageUploading {
        var isConfigured: Bool = true
        private(set) var uploads: [(folder: HeroImageFolder, id: Int64, full: Data, thumb: Data)] = []
        var publicBaseURL = "https://images.duskroute.com"

        func uploadHero(folder: HeroImageFolder, id: Int64, jpegData: Data, thumbJpegData: Data) async throws -> URL {
            uploads.append((folder, id, jpegData, thumbJpegData))
            return URL(string: "\(publicBaseURL)/\(folder.rawValue)/\(id).jpg")!
        }
    }

    private func makeFixture(
        urlSession: URLSessionProtocol? = nil,
        uploader: FakeHeroUploader? = nil
    ) throws -> (
        store: RegionHeroImageStore,
        repository: GeographicRegionRepository,
        sqlStore: SQLStore,
        heroDirectory: URL,
        uploader: FakeHeroUploader
    ) {
        let heroDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sqlStore = SQLStore.inMemory()
        let repository = GeographicRegionRepository(store: sqlStore)
        let cache = CrawlImageCache(directory: cacheDirectory)
        let fetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: urlSession ?? FakeURLSession { _ in
                throw CrawlImageFetcherError.invalidResponse
            }
        )
        let resolvedUploader = uploader ?? FakeHeroUploader()
        let store = RegionHeroImageStore(
            directory: heroDirectory,
            geographicRegionRepository: repository,
            imageFetcher: fetcher,
            uploader: resolvedUploader
        )
        return (store, repository, sqlStore, heroDirectory, resolvedUploader)
    }

    private func firstRegionId(store: SQLStore) throws -> Int64 {
        try store.dbQueue.read { db in
            let region = try #require(try GeographicRegion.fetchOne(db))
            return try #require(region.id)
        }
    }

    private func jpegResponse(for url: URL) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/jpeg"]
        )!
    }

    @Test func setDownloadsUploadsAndPersistsSourceAndCDNURL() async throws {
        let remoteURL = URL(string: "https://example.com/region-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let regionId = try firstRegionId(store: fixture.sqlStore)

        try await fixture.store.setHeroImage(regionId: regionId, remoteURL: remoteURL)

        let region = try #require(try fixture.repository.find(id: regionId))
        #expect(region.heroImage == remoteURL.absoluteString)
        let r2URL = try #require(region.heroR2Url.flatMap(URL.init(string:)))
        #expect(r2URL.scheme == "https")
        #expect(r2URL.host == "images.duskroute.com")
        #expect(r2URL.path == "/regions/\(regionId).jpg")
        #expect(fixture.uploader.uploads.count == 1)
        #expect(fixture.uploader.uploads[0].folder == .regions)
        #expect(!fixture.uploader.uploads[0].thumb.isEmpty)
        #expect(!fixture.uploader.uploads[0].full.isEmpty)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(regionId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(regionId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))
    }

    @Test func setRequiresR2Configuration() async throws {
        let uploader = FakeHeroUploader()
        uploader.isConfigured = false
        let remoteURL = URL(string: "https://example.com/region-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL)),
            uploader: uploader
        )
        let regionId = try firstRegionId(store: fixture.sqlStore)

        await #expect(throws: RegionHeroImageStoreError.r2NotConfigured) {
            try await fixture.store.setHeroImage(regionId: regionId, remoteURL: remoteURL)
        }
    }

    @Test func clearRemovesLocalFilesAndDatabaseFields() async throws {
        let remoteURL = URL(string: "https://example.com/region-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let regionId = try firstRegionId(store: fixture.sqlStore)

        try await fixture.store.setHeroImage(regionId: regionId, remoteURL: remoteURL)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(regionId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(regionId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))

        try fixture.store.clearHeroImage(regionId: regionId)

        let region = try #require(try fixture.repository.find(id: regionId))
        #expect(region.heroImage == nil)
        #expect(region.heroR2Url == nil)
        #expect(!FileManager.default.fileExists(atPath: localFile.path))
        #expect(!FileManager.default.fileExists(atPath: localThumb.path))
    }
}
