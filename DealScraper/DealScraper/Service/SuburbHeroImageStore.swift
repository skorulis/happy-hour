//Created by Alexander Skorulis on 19/7/2026.

import Foundation

enum SuburbHeroImageStoreError: LocalizedError, Equatable {
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
final class SuburbHeroImageStore {

    let directory: URL

    private let suburbRepository: SuburbRepository
    private let imageFetcher: CrawlImageFetcher
    private let uploader: HeroImageUploading

    init(
        directory: URL? = nil,
        suburbRepository: SuburbRepository,
        imageFetcher: CrawlImageFetcher,
        uploader: HeroImageUploading
    ) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = SQLStore.docDir
                .appendingPathComponent("DealScraper/suburb-hero-images", isDirectory: true)
        }
        self.suburbRepository = suburbRepository
        self.imageFetcher = imageFetcher
        self.uploader = uploader

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func setHeroImage(suburbId: Int64, remoteURL: URL) async throws {
        guard uploader.isConfigured else {
            throw SuburbHeroImageStoreError.r2NotConfigured
        }

        try deleteStoredImage(for: suburbId)

        let hash = URLNormalizer.hash(remoteURL)
        let downloadedURL = try await imageFetcher.localFileURL(for: remoteURL, hash: hash)
        let sourceData = try Data(contentsOf: downloadedURL)
        let optimized = try HeroImageOptimizer.optimize(sourceData)

        let destination = directory.appendingPathComponent("\(suburbId).jpg")
        let thumbDestination = directory.appendingPathComponent("\(suburbId)-thumb.jpg")
        try optimized.full.write(to: destination, options: .atomic)
        try optimized.thumb.write(to: thumbDestination, options: .atomic)

        let publicURL = try await uploader.uploadHero(
            folder: .suburbs,
            id: suburbId,
            jpegData: optimized.full,
            thumbJpegData: optimized.thumb
        )
        try suburbRepository.updateHeroImage(suburbId: suburbId, url: remoteURL.absoluteString)
        try suburbRepository.updateHeroR2Url(suburbId: suburbId, url: publicURL.absoluteString)
    }

    func clearHeroImage(suburbId: Int64) throws {
        try deleteStoredImage(for: suburbId)
        try suburbRepository.clearHeroImageFields(suburbId: suburbId)
    }

    func deleteStoredImage(for suburbId: Int64) throws {
        let names = Set(["\(suburbId).jpg", "\(suburbId)-thumb.jpg"])
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in contents where names.contains(fileURL.lastPathComponent) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
