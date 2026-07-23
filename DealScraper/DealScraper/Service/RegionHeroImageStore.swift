//Created by Alexander Skorulis on 23/7/2026.

import Foundation

enum RegionHeroImageStoreError: LocalizedError, Equatable {
    case r2NotConfigured
    case invalidHeroSourceURL(String)

    var errorDescription: String? {
        switch self {
        case .r2NotConfigured:
            return "Cloudflare R2 is not configured. Add credentials in Settings before setting hero images."
        case .invalidHeroSourceURL(let value):
            return "Hero image source URL is invalid: \(value)"
        }
    }
}

@MainActor
final class RegionHeroImageStore {

    let directory: URL

    private let geographicRegionRepository: GeographicRegionRepository
    private let imageFetcher: CrawlImageFetcher
    private let uploader: HeroImageUploading

    init(
        directory: URL? = nil,
        geographicRegionRepository: GeographicRegionRepository,
        imageFetcher: CrawlImageFetcher,
        uploader: HeroImageUploading
    ) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = SQLStore.docDir
                .appendingPathComponent("DealScraper/region-hero-images", isDirectory: true)
        }
        self.geographicRegionRepository = geographicRegionRepository
        self.imageFetcher = imageFetcher
        self.uploader = uploader

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func setHeroImage(regionId: Int64, remoteURL: URL) async throws {
        guard uploader.isConfigured else {
            throw RegionHeroImageStoreError.r2NotConfigured
        }

        try deleteStoredImage(for: regionId)

        let hash = URLNormalizer.hash(remoteURL)
        let downloadedURL = try await imageFetcher.localFileURL(for: remoteURL, hash: hash)
        let sourceData = try Data(contentsOf: downloadedURL)
        let optimized = try HeroImageOptimizer.optimize(sourceData)

        let destination = directory.appendingPathComponent("\(regionId).jpg")
        let thumbDestination = directory.appendingPathComponent("\(regionId)-thumb.jpg")
        try optimized.full.write(to: destination, options: .atomic)
        try optimized.thumb.write(to: thumbDestination, options: .atomic)

        let publicURL = try await uploader.uploadHero(
            folder: .regions,
            id: regionId,
            jpegData: optimized.full,
            thumbJpegData: optimized.thumb
        )
        try geographicRegionRepository.updateHeroImage(regionId: regionId, url: remoteURL.absoluteString)
        try geographicRegionRepository.updateHeroR2Url(regionId: regionId, url: publicURL.absoluteString)
    }

    func clearHeroImage(regionId: Int64) throws {
        try deleteStoredImage(for: regionId)
        try geographicRegionRepository.clearHeroImageFields(regionId: regionId)
    }

    func deleteStoredImage(for regionId: Int64) throws {
        let names = Set(["\(regionId).jpg", "\(regionId)-thumb.jpg"])
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in contents where names.contains(fileURL.lastPathComponent) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
