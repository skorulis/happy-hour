//Created by Alex Skorulis on 19/6/2026.

import Foundation

final class CrawlPDFCache: @unchecked Sendable {

    let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.directory = caches.appendingPathComponent("DealScraper/pdf-cache", isDirectory: true)
        }

        print("Caching PDFs in: \(self.directory.path)")

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func findCachedFileURL(for hash: String) -> URL? {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        return files.first { $0.deletingPathExtension().lastPathComponent == hash }
    }

    func store(data: Data, hash: String, fileExtension: String) throws -> URL {
        let sanitizedExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ext = sanitizedExtension.isEmpty ? "pdf" : sanitizedExtension
        let fileURL = directory.appendingPathComponent("\(hash).\(ext)")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
