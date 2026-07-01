//Created by Alex Skorulis on 15/6/2026.

import Foundation

final class CrawlImageCache: @unchecked Sendable {

    let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.directory = caches.appendingPathComponent("DealScraper/image-cache", isDirectory: true)
        }
        
        print("Caching images in: \(self.directory.path)")

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func findCachedFileURL(for hash: String) -> URL? {
        let fileURL = directory.appendingPathComponent(hash)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }

    func store(data: Data, hash: String, fileExtension: String) throws -> URL {
        let fileURL = directory.appendingPathComponent(hash)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
