//Created by Alex Skorulis on 2/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct VenueHeroImageStoreTests {

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

        func clearUploads() {
            uploads.removeAll()
        }
    }

    private func makeFixture(
        urlSession: URLSessionProtocol? = nil,
        uploader: FakeHeroUploader? = nil
    ) throws -> (
        store: VenueHeroImageStore,
        repository: VenueRepository,
        heroDirectory: URL,
        cacheDirectory: URL,
        uploader: FakeHeroUploader
    ) {
        let heroDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sqlStore = SQLStore.inMemory()
        let repository = VenueRepository(store: sqlStore)
        let cache = CrawlImageCache(directory: cacheDirectory)
        let fetcher = CrawlImageFetcher(
            cache: cache,
            urlSession: urlSession ?? FakeURLSession { _ in
                throw CrawlImageFetcherError.invalidResponse
            }
        )
        let resolvedUploader = uploader ?? FakeHeroUploader()
        let store = VenueHeroImageStore(
            directory: heroDirectory,
            venueRepository: repository,
            imageFetcher: fetcher,
            uploader: resolvedUploader
        )
        return (store, repository, heroDirectory, cacheDirectory, resolvedUploader)
    }

    private func insertVenue(in repository: VenueRepository) throws -> Int64 {
        try repository.upsert(Venue(
            googleMapId: "places/ChIJHeroTest",
            name: "Hero Test Pub",
            lat: -33.8688,
            lng: 151.2093,
            json: "{}"
        ))
        return try #require(try repository.find(googleMapId: "places/ChIJHeroTest")?.id)
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
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let imageData = Self.sampleImage
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: imageData, response: jpegResponse(for: remoteURL))
        )
        let venueId = try insertVenue(in: fixture.repository)

        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let venue = try #require(try fixture.repository.find(id: venueId))
        #expect(venue.heroImage == remoteURL.absoluteString)
        let r2URL = try #require(venue.heroR2Url.flatMap(URL.init(string:)))
        #expect(r2URL.scheme == "https")
        #expect(r2URL.host == "images.duskroute.com")
        #expect(r2URL.path == "/venues/\(venueId).jpg")
        #expect(r2URL.pathExtension == "jpg")
        #expect(fixture.uploader.uploads.count == 1)
        #expect(!fixture.uploader.uploads[0].thumb.isEmpty)
        #expect(!fixture.uploader.uploads[0].full.isEmpty)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(venueId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(venueId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))
        #expect(!fixture.store.isManagedLocalURL(r2URL.absoluteString))
    }

    @Test func setRequiresR2Configuration() async throws {
        let uploader = FakeHeroUploader()
        uploader.isConfigured = false
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL)),
            uploader: uploader
        )
        let venueId = try insertVenue(in: fixture.repository)

        await #expect(throws: VenueHeroImageStoreError.r2NotConfigured) {
            try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)
        }
    }

    @Test func setUsesExistingCacheWithoutDownloading() async throws {
        let remoteURL = URL(string: "https://example.com/cached-hero.jpg")!
        let imageData = Self.sampleImage
        let fixture = try makeFixture()
        let cache = CrawlImageCache(directory: fixture.cacheDirectory)
        _ = try cache.store(
            data: imageData,
            hash: URLNormalizer.hash(remoteURL),
            fileExtension: "jpg"
        )

        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let venue = try #require(try fixture.repository.find(id: venueId))
        #expect(venue.heroImage == remoteURL.absoluteString)
        #expect(venue.heroR2Url?.hasPrefix("https://images.duskroute.com/") == true)
        #expect(fixture.uploader.uploads.count == 1)
    }

    @Test func replaceUploadsAgainAndReplacesLocalFile() async throws {
        let firstURL = URL(string: "https://example.com/first.jpg")!
        let secondURL = URL(string: "https://example.com/second.jpg")!

        let sampleImage = Self.sampleImage
        let fixture = try makeFixture(
            urlSession: FakeURLSession { request in
                guard let url = request.url else {
                    throw CrawlImageFetcherError.invalidResponse
                }
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "image/jpeg"]
                )!
                return (sampleImage, response)
            }
        )
        let venueId = try insertVenue(in: fixture.repository)

        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: firstURL)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: secondURL)

        #expect(fixture.uploader.uploads.count == 2)
        let localFile = fixture.heroDirectory.appendingPathComponent("\(venueId).jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        let venue = try #require(try fixture.repository.find(id: venueId))
        #expect(venue.heroImage == secondURL.absoluteString)
        #expect(venue.heroR2Url?.hasPrefix("https://images.duskroute.com/") == true)
    }

    @Test func clearRemovesLocalFileAndNullsDatabase() async throws {
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let localFile = fixture.heroDirectory.appendingPathComponent("\(venueId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(venueId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))

        try fixture.store.clearHeroImage(venueId: venueId)

        let venue = try #require(try fixture.repository.find(id: venueId))
        #expect(venue.heroImage == nil)
        #expect(venue.heroR2Url == nil)
        #expect(!FileManager.default.fileExists(atPath: localFile.path))
        #expect(!FileManager.default.fileExists(atPath: localThumb.path))
    }

    @Test func deleteStoredImageRemovesFileWithoutUpdatingDatabase() async throws {
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let heroURL = try #require(try fixture.repository.find(id: venueId)?.heroImage)
        let heroR2URL = try #require(try fixture.repository.find(id: venueId)?.heroR2Url)
        let localFile = fixture.heroDirectory.appendingPathComponent("\(venueId).jpg")
        let localThumb = fixture.heroDirectory.appendingPathComponent("\(venueId)-thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: localFile.path))
        #expect(FileManager.default.fileExists(atPath: localThumb.path))

        try fixture.store.deleteStoredImage(for: venueId)

        #expect(!FileManager.default.fileExists(atPath: localFile.path))
        #expect(!FileManager.default.fileExists(atPath: localThumb.path))
        #expect(try fixture.repository.find(id: venueId)?.heroImage == heroURL)
        #expect(try fixture.repository.find(id: venueId)?.heroR2Url == heroR2URL)
    }

    @Test func uploadMissingR2CopiesCDNSourceWithoutReupload() async throws {
        let fixture = try makeFixture()
        let venueId = try insertVenue(in: fixture.repository)
        let cdnURL = "https://images.duskroute.com/venues/\(venueId).jpg"
        try fixture.repository.updateHeroImage(venueId: venueId, url: cdnURL)

        let venue = try #require(try fixture.repository.find(id: venueId))
        let uploaded = try await fixture.store.uploadMissingR2IfNeeded(venue: venue)

        #expect(uploaded)
        #expect(fixture.uploader.uploads.isEmpty)
        let updated = try #require(try fixture.repository.find(id: venueId))
        #expect(updated.heroImage == cdnURL)
        #expect(updated.heroR2Url == cdnURL)
    }

    @Test func uploadMissingR2UploadsFromRemoteSource() async throws {
        let remoteURL = URL(string: "https://example.com/legacy-hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let venueId = try insertVenue(in: fixture.repository)
        try fixture.repository.updateHeroImage(venueId: venueId, url: remoteURL.absoluteString)

        let venue = try #require(try fixture.repository.find(id: venueId))
        let uploaded = try await fixture.store.uploadMissingR2IfNeeded(venue: venue)

        #expect(uploaded)
        #expect(fixture.uploader.uploads.count == 1)
        let updated = try #require(try fixture.repository.find(id: venueId))
        #expect(updated.heroImage == remoteURL.absoluteString)
        #expect(updated.heroR2Url == "https://images.duskroute.com/venues/\(venueId).jpg")
    }

    @Test func uploadMissingR2UploadsFromLocalFile() async throws {
        let fixture = try makeFixture()
        let venueId = try insertVenue(in: fixture.repository)
        let localFile = fixture.heroDirectory.appendingPathComponent("\(venueId).png")
        try Self.sampleImage.write(to: localFile, options: .atomic)
        try fixture.repository.updateHeroImage(venueId: venueId, url: localFile.absoluteString)

        let venue = try #require(try fixture.repository.find(id: venueId))
        let uploaded = try await fixture.store.uploadMissingR2IfNeeded(venue: venue)

        #expect(uploaded)
        #expect(fixture.uploader.uploads.count == 1)
        let updated = try #require(try fixture.repository.find(id: venueId))
        #expect(updated.heroImage == localFile.absoluteString)
        #expect(updated.heroR2Url == "https://images.duskroute.com/venues/\(venueId).jpg")
    }

    @Test func uploadMissingR2SkipsWhenAlreadyUploaded() async throws {
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: Self.sampleImage, response: jpegResponse(for: remoteURL))
        )
        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)
        fixture.uploader.clearUploads()

        let venue = try #require(try fixture.repository.find(id: venueId))
        let uploaded = try await fixture.store.uploadMissingR2IfNeeded(venue: venue)

        #expect(!uploaded)
        #expect(fixture.uploader.uploads.isEmpty)
    }
}
