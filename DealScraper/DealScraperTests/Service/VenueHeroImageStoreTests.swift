//Created by Alex Skorulis on 2/7/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct VenueHeroImageStoreTests {

    private func makeFixture(
        urlSession: URLSessionProtocol? = nil
    ) throws -> (
        store: VenueHeroImageStore,
        repository: VenueRepository,
        heroDirectory: URL,
        cacheDirectory: URL
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
        let store = VenueHeroImageStore(
            directory: heroDirectory,
            venueRepository: repository,
            imageFetcher: fetcher
        )
        return (store, repository, heroDirectory, cacheDirectory)
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

    @Test func setDownloadsAndPersistsLocalURL() async throws {
        let remoteURL = URL(string: "https://example.com/hero.jpg")!
        let imageData = Data("hero-image-bytes".utf8)
        let response = HTTPURLResponse(
            url: remoteURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/jpeg"]
        )!

        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: imageData, response: response)
        )
        let venueId = try insertVenue(in: fixture.repository)

        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let venue = try #require(try fixture.repository.find(id: venueId))
        let heroURL = try #require(venue.heroImage.flatMap(URL.init(string:)))
        #expect(fixture.store.isManagedLocalURL(heroURL.absoluteString))
        #expect(heroURL.pathExtension == "jpg")
        #expect(heroURL.lastPathComponent == "\(venueId).jpg")
        #expect(try Data(contentsOf: heroURL) == imageData)
    }

    @Test func setUsesExistingCacheWithoutDownloading() async throws {
        let remoteURL = URL(string: "https://example.com/cached-hero.png")!
        let imageData = Data("cached-hero-bytes".utf8)
        let fixture = try makeFixture()
        let cache = CrawlImageCache(directory: fixture.cacheDirectory)
        _ = try cache.store(
            data: imageData,
            hash: URLNormalizer.hash(remoteURL),
            fileExtension: "png"
        )

        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let venue = try #require(try fixture.repository.find(id: venueId))
        let heroURL = try #require(venue.heroImage.flatMap(URL.init(string:)))
        #expect(heroURL.lastPathComponent == "\(venueId).png")
        #expect(try Data(contentsOf: heroURL) == imageData)
    }

    @Test func replaceDeletesPreviousFile() async throws {
        let firstURL = URL(string: "https://example.com/first.jpg")!
        let secondURL = URL(string: "https://example.com/second.png")!
        let firstData = Data("first-image".utf8)
        let secondData = Data("second-image".utf8)

        let fixture = try makeFixture(
            urlSession: FakeURLSession { request in
                guard let url = request.url else {
                    throw CrawlImageFetcherError.invalidResponse
                }
                let data: Data
                let response: HTTPURLResponse
                if url.absoluteString == firstURL.absoluteString {
                    data = firstData
                    response = HTTPURLResponse(
                        url: firstURL,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/jpeg"]
                    )!
                } else if url.absoluteString == secondURL.absoluteString {
                    data = secondData
                    response = HTTPURLResponse(
                        url: secondURL,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/png"]
                    )!
                } else {
                    throw CrawlImageFetcherError.invalidResponse
                }
                return (data, response)
            }
        )
        let venueId = try insertVenue(in: fixture.repository)

        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: firstURL)
        let firstHeroURL = try #require(
            try fixture.repository.find(id: venueId)?.heroImage.flatMap(URL.init(string:))
        )

        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: secondURL)
        let secondHeroURL = try #require(
            try fixture.repository.find(id: venueId)?.heroImage.flatMap(URL.init(string:))
        )

        #expect(!FileManager.default.fileExists(atPath: firstHeroURL.path))
        #expect(FileManager.default.fileExists(atPath: secondHeroURL.path))
        #expect(secondHeroURL.lastPathComponent == "\(venueId).png")
        #expect(try Data(contentsOf: secondHeroURL) == secondData)
    }

    @Test func clearRemovesFileAndNullsDatabase() async throws {
        let remoteURL = URL(string: "https://example.com/hero.webp")!
        let imageData = Data("hero-to-clear".utf8)
        let response = HTTPURLResponse(
            url: remoteURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/webp"]
        )!

        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: imageData, response: response)
        )
        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let heroURL = try #require(
            try fixture.repository.find(id: venueId)?.heroImage.flatMap(URL.init(string:))
        )
        #expect(FileManager.default.fileExists(atPath: heroURL.path))

        try fixture.store.clearHeroImage(venueId: venueId)

        let venue = try #require(try fixture.repository.find(id: venueId))
        #expect(venue.heroImage == nil)
        #expect(!FileManager.default.fileExists(atPath: heroURL.path))
    }

    @Test func deleteStoredImageRemovesFileWithoutUpdatingDatabase() async throws {
        let remoteURL = URL(string: "https://example.com/hero.gif")!
        let imageData = Data("hero-to-delete".utf8)
        let response = HTTPURLResponse(
            url: remoteURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/gif"]
        )!

        let fixture = try makeFixture(
            urlSession: FakeURLSession(data: imageData, response: response)
        )
        let venueId = try insertVenue(in: fixture.repository)
        try await fixture.store.setHeroImage(venueId: venueId, remoteURL: remoteURL)

        let heroURL = try #require(
            try fixture.repository.find(id: venueId)?.heroImage.flatMap(URL.init(string:))
        )
        #expect(FileManager.default.fileExists(atPath: heroURL.path))

        try fixture.store.deleteStoredImage(for: venueId)

        #expect(!FileManager.default.fileExists(atPath: heroURL.path))
        #expect(try fixture.repository.find(id: venueId)?.heroImage == heroURL.absoluteString)
    }
}
