//Created by Alex Skorulis on 17/6/2026.

import Foundation

enum VenueDealSourceMaterialPreparerError: LocalizedError {
    case noMaterialsPrepared(failures: [String])

    var errorDescription: String? {
        switch self {
        case let .noMaterialsPrepared(failures):
            if failures.isEmpty {
                return "No deal sources could be prepared for extraction."
            }
            return "No deal sources could be prepared for extraction:\n" + failures.joined(separator: "\n")
        }
    }
}

@MainActor
final class VenueDealSourceMaterialPreparer {

    static let maxSources = 10

    private let imageFetcher: CrawlImageFetcher

    init(imageFetcher: CrawlImageFetcher) {
        self.imageFetcher = imageFetcher
    }

    func prepare(
        sources: [DealSource],
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> [VenueDealSourceMaterial] {
        let capped = Array(sources.prefix(Self.maxSources))
        var materials: [VenueDealSourceMaterial] = []
        var failures: [String] = []

        for (offset, source) in capped.enumerated() {
            let index = offset + 1
            onProgress?("Preparing source \(index) of \(capped.count)…")

            guard let sourceID = source.id,
                  let url = URL(string: source.url)
            else {
                failures.append("Source \(index): invalid URL")
                continue
            }

            let sourceURL = URL(string: source.sourceURL) ?? url

            do {
                let pngData: Data?
                switch source.type {
                case .image:
                    pngData = try await prepareImage(url: url)
                case .webpage:
                    pngData = nil
                case .pdf:
                    continue
                }

                materials.append(
                    VenueDealSourceMaterial(
                        index: index,
                        dealSourceId: sourceID,
                        url: url,
                        sourceURL: sourceURL,
                        type: source.type,
                        pngData: pngData
                    )
                )
            } catch {
                failures.append("Source \(index) (\(source.url)): \(error.localizedDescription)")
            }
        }

        guard !materials.isEmpty else {
            throw VenueDealSourceMaterialPreparerError.noMaterialsPrepared(failures: failures)
        }

        return materials
    }

    func prepareLocalImage(at url: URL) throws -> VenueDealSourceMaterial {
        let pngData = try ImagePNGConverter.pngData(from: url)
        return VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 0,
            url: url,
            sourceURL: url,
            type: .image,
            pngData: pngData
        )
    }

    private func prepareImage(url: URL) async throws -> Data {
        let hash = URLNormalizer.hash(url)
        let localURL = try await imageFetcher.localFileURL(for: url, hash: hash)
        return try ImagePNGConverter.pngData(from: localURL)
    }
}
