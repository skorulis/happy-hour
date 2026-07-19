//Created by Alex Skorulis on 2/7/2026.

import Foundation

enum VenueHeroImageStoreError: LocalizedError, Equatable {
    case r2NotConfigured
    case missingHeroSource
    case invalidHeroSourceURL(String)

    var errorDescription: String? {
        switch self {
        case .r2NotConfigured:
            return "Cloudflare R2 is not configured. Add credentials in Settings before setting hero images."
        case .missingHeroSource:
            return "Venue has no hero image source to upload."
        case .invalidHeroSourceURL(let value):
            return "Hero image source URL is invalid: \(value)"
        }
    }
}

@MainActor
final class VenueHeroImageStore {

    let directory: URL

    private let venueRepository: VenueRepository
    private let imageFetcher: CrawlImageFetcher
    private let uploader: HeroImageUploading

    init(
        directory: URL? = nil,
        venueRepository: VenueRepository,
        imageFetcher: CrawlImageFetcher,
        uploader: HeroImageUploading
    ) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = SQLStore.docDir
                .appendingPathComponent("DealScraper/hero-images", isDirectory: true)
        }
        self.venueRepository = venueRepository
        self.imageFetcher = imageFetcher
        self.uploader = uploader

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func setHeroImage(venueId: Int64, remoteURL: URL) async throws {
        guard uploader.isConfigured else {
            throw VenueHeroImageStoreError.r2NotConfigured
        }

        try deleteStoredImage(for: venueId)

        let hash = URLNormalizer.hash(remoteURL)
        let downloadedURL = try await imageFetcher.localFileURL(for: remoteURL, hash: hash)
        let sourceData = try Data(contentsOf: downloadedURL)
        let optimized = try HeroImageOptimizer.optimize(sourceData)

        let destination = directory.appendingPathComponent("\(venueId).jpg")
        let thumbDestination = directory.appendingPathComponent("\(venueId)-thumb.jpg")
        try optimized.full.write(to: destination, options: .atomic)
        try optimized.thumb.write(to: thumbDestination, options: .atomic)

        let publicURL = try await uploader.uploadHero(
            folder: .venues,
            id: venueId,
            jpegData: optimized.full,
            thumbJpegData: optimized.thumb
        )
        try venueRepository.updateHeroImage(venueId: venueId, url: remoteURL.absoluteString)
        try venueRepository.updateHeroR2Url(venueId: venueId, url: publicURL.absoluteString)
    }

    /// Uploads to R2 when `hero_r2_url` is missing. Leaves `hero_image` unchanged.
    @discardableResult
    func uploadMissingR2IfNeeded(venue: Venue) async throws -> Bool {
        guard let venueId = venue.id else {
            return false
        }
        if let existing = venue.heroR2Url, !existing.isEmpty {
            return false
        }
        guard let source = venue.heroImage?.trimmingCharacters(in: .whitespacesAndNewlines),
              !source.isEmpty
        else {
            throw VenueHeroImageStoreError.missingHeroSource
        }

        if isPublicCDNURL(source) {
            try venueRepository.updateHeroR2Url(venueId: venueId, url: source)
            return true
        }

        guard uploader.isConfigured else {
            throw VenueHeroImageStoreError.r2NotConfigured
        }

        let sourceData = try await loadSourceData(from: source)
        let optimized = try HeroImageOptimizer.optimize(sourceData)

        let destination = directory.appendingPathComponent("\(venueId).jpg")
        let thumbDestination = directory.appendingPathComponent("\(venueId)-thumb.jpg")
        try optimized.full.write(to: destination, options: .atomic)
        try optimized.thumb.write(to: thumbDestination, options: .atomic)

        let publicURL = try await uploader.uploadHero(
            folder: .venues,
            id: venueId,
            jpegData: optimized.full,
            thumbJpegData: optimized.thumb
        )
        try venueRepository.updateHeroR2Url(venueId: venueId, url: publicURL.absoluteString)
        return true
    }

    func clearHeroImage(venueId: Int64) throws {
        try deleteStoredImage(for: venueId)
        try venueRepository.clearHeroImageFields(venueId: venueId)
    }

    func deleteStoredImage(for venueId: Int64) throws {
        let names = Set(["\(venueId).jpg", "\(venueId)-thumb.jpg"])
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in contents where names.contains(fileURL.lastPathComponent) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func isManagedLocalURL(_ string: String) -> Bool {
        guard let url = URL(string: string), url.isFileURL else {
            return false
        }
        return url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path)
    }

    private func isPublicCDNURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let host = url.host?.lowercased()
        else {
            return false
        }
        let base = uploader.publicBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let baseURL = URL(string: base),
              let baseHost = baseURL.host?.lowercased()
        else {
            return false
        }
        return host == baseHost
    }

    private func loadSourceData(from source: String) async throws -> Data {
        guard let url = URL(string: source) else {
            throw VenueHeroImageStoreError.invalidHeroSourceURL(source)
        }
        if url.isFileURL {
            return try Data(contentsOf: url)
        }
        let hash = URLNormalizer.hash(url)
        let downloadedURL = try await imageFetcher.localFileURL(for: url, hash: hash)
        return try Data(contentsOf: downloadedURL)
    }
}
