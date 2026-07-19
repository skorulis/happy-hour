//Created by Alexander Skorulis on 19/7/2026.

import ASKCore
import Foundation
import GRDB
import Testing
@testable import DealScraper

@MainActor
struct SuburbHeroImageStoreTests {

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
        store: SuburbHeroImageStore,
        repository: SuburbRepository,
        sqlStore: SQLStore,
        heroDirectory: URL,
        uploader: FakeHeroUploader
    ) {
        let heroDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sqlStore = SQLStore.inMemory()
        let repository = SuburbRepository(store: sqlStore)
        let cache = CrawlImageCache(directory: cacheDirectory)
        let fetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: urlSession ?? FakeURLSession { _ in
                throw CrawlImageFetcherError.invalidResponse
            }
        )
        let resolvedUploader = uploader ?? FakeHeroUploader()
        let store = SuburbHeroImageStore(
            directory: heroDirectory,
            suburbRepository: repository,
            imageFetcher: fetcher,
            uploader: resolvedUploader
        )
        return (store, repository, sqlStore, heroDirectory, resolvedUploader)
    }

    private func insertSuburb(store: SQLStore) throws -> Int64 {
        try store.dbQueue.write { db in
            var suburb = Suburb(name: "Newtown", postcode: "2042", state: "NSW")
            try suburb.insert(db)
            return try #require(suburb.id)
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
        let remoteURL = URL(string: "https://example.com/suburb-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let suburbId = try insertSuburb(store: fixture.sqlStore)

        try await fixture.store.setHeroImage(suburbId: suburbId, remoteURL: remoteURL)

        let suburb = try #require(try fixture.repository.find(id: suburbId))
        #expect(suburb.heroImage == remoteURL.absoluteString)
        let r2URL = try #require(suburb.heroR2Url.flatMap(URL.init(string:)))
        #expect(r2URL.scheme == "https")
        #expect(r2URL.host == "images.duskroute.com")
        #expect(r2URL.path == "/suburbs/\(suburbId).jpg")
        #expect(fixture.uploader.uploads.count == 1)
        #expect(fixture.uploader.uploads[0].folder == .suburbs)
        #expect(!fixture.uploader.uploads[0].thumb.isEmpty)
        #expect(!fixture.uploader.uploads[0].full.isEmpty)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(suburbId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(suburbId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))
    }

    @Test func setRequiresR2Configuration() async throws {
        let uploader = FakeHeroUploader()
        uploader.isConfigured = false
        let remoteURL = URL(string: "https://example.com/suburb-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL)),
            uploader: uploader
        )
        let suburbId = try insertSuburb(store: fixture.sqlStore)

        await #expect(throws: SuburbHeroImageStoreError.r2NotConfigured) {
            try await fixture.store.setHeroImage(suburbId: suburbId, remoteURL: remoteURL)
        }
    }

    @Test func clearRemovesLocalFilesAndDatabaseFields() async throws {
        let remoteURL = URL(string: "https://example.com/suburb-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let suburbId = try insertSuburb(store: fixture.sqlStore)

        try await fixture.store.setHeroImage(suburbId: suburbId, remoteURL: remoteURL)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(suburbId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(suburbId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))

        try fixture.store.clearHeroImage(suburbId: suburbId)

        let suburb = try #require(try fixture.repository.find(id: suburbId))
        #expect(suburb.heroImage == nil)
        #expect(suburb.heroR2Url == nil)
        #expect(!FileManager.default.fileExists(atPath: localFile.path))
        #expect(!FileManager.default.fileExists(atPath: localThumb.path))
    }
}
