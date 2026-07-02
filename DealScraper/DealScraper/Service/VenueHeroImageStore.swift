//Created by Alex Skorulis on 2/7/2026.

import Foundation

@MainActor
final class VenueHeroImageStore {

    let directory: URL

    private let venueRepository: VenueRepository
    private let imageFetcher: CrawlImageFetcher

    init(
        directory: URL? = nil,
        venueRepository: VenueRepository,
        imageFetcher: CrawlImageFetcher
    ) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = SQLStore.docDir
                .appendingPathComponent("DealScraper/hero-images", isDirectory: true)
        }
        self.venueRepository = venueRepository
        self.imageFetcher = imageFetcher

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func setHeroImage(venueId: Int64, remoteURL: URL) async throws {
        try deleteStoredImage(for: venueId)

        let hash = URLNormalizer.hash(remoteURL)
        let downloadedURL = try await imageFetcher.localFileURL(for: remoteURL, hash: hash)
        let data = try Data(contentsOf: downloadedURL)
        let fileExtension = Self.fileExtension(for: remoteURL)
        let destination = directory.appendingPathComponent("\(venueId).\(fileExtension)")

        try data.write(to: destination, options: .atomic)
        try venueRepository.updateHeroImage(venueId: venueId, url: destination.absoluteString)
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

    private static func fileExtension(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return pathExtension
        }
        return "img"
    }
}
