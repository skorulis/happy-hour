//Created by Alex Skorulis on 2/7/2026.

import Foundation

enum VenueHeroImageStoreError: LocalizedError {
    case r2NotConfigured

    var errorDescription: String? {
        switch self {
        case .r2NotConfigured:
            return "Cloudflare R2 is not configured. Add credentials in Settings before setting hero images."
        }
    }
}

@MainActor
final class VenueHeroImageStore {

    let directory: URL

    private let venueRepository: VenueRepository
    private let imageFetcher: CrawlImageFetcher
    private let uploader: VenueHeroImageUploading

    init(
        directory: URL? = nil,
        venueRepository: VenueRepository,
        imageFetcher: CrawlImageFetcher,
        uploader: VenueHeroImageUploading
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
        try optimized.write(to: destination, options: .atomic)

        let publicURL = try await uploader.uploadHero(
            venueId: venueId,
            jpegData: optimized
        )
        try venueRepository.updateHeroImage(venueId: venueId, url: publicURL.absoluteString)
    }

    func clearHeroImage(venueId: Int64) throws {
        try deleteStoredImage(for: venueId)
        try venueRepository.updateHeroImage(venueId: venueId, url: nil)
    }

    func deleteStoredImage(for venueId: Int64) throws {
        let prefix = "\(venueId)."
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in contents where fileURL.lastPathComponent.hasPrefix(prefix) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func isManagedLocalURL(_ string: String) -> Bool {
        guard let url = URL(string: string), url.isFileURL else {
            return false
        }
        return url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path)
    }
}
