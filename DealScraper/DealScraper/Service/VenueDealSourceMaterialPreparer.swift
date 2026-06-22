//Created by Alex Skorulis on 17/6/2026.

import Foundation
import UniformTypeIdentifiers

enum VenueDealSourceMaterialPreparerError: LocalizedError, Equatable {
    case noMaterialsPrepared(failures: [String])
    case missingMarkdown
    case missingPDFText

    var errorDescription: String? {
        switch self {
        case let .noMaterialsPrepared(failures):
            if failures.isEmpty {
                return "No deal sources could be prepared for extraction."
            }
            return "No deal sources could be prepared for extraction:\n" + failures.joined(separator: "\n")
        case .missingMarkdown:
            return "The webpage loaded but contained no convertible markdown content."
        case .missingPDFText:
            return "No text could be extracted from the PDF."
        }
    }
}

@MainActor
final class VenueDealSourceMaterialPreparer {

    static let maxSources = 10

    private let imageFetcher: CrawlImageFetcher
    private let webPageLoader: WebPageLoader
    private let pdfFetcher: CrawlPDFFetcher
    private let pdfTextExtractor: PDFTextExtractor

    init(
        imageFetcher: CrawlImageFetcher,
        webPageLoader: WebPageLoader,
        pdfFetcher: CrawlPDFFetcher,
        pdfTextExtractor: PDFTextExtractor
    ) {
        self.imageFetcher = imageFetcher
        self.webPageLoader = webPageLoader
        self.pdfFetcher = pdfFetcher
        self.pdfTextExtractor = pdfTextExtractor
    }

    func prepare<Result>(
        sources: [DealSource],
        progress: ProgressMonitor<Result> = .empty
    ) async throws -> [VenueDealSourceMaterial] {
        let capped = Array(sources.prefix(Self.maxSources))
        var materials: [VenueDealSourceMaterial] = []
        var failures: [String] = []

        for (offset, source) in capped.enumerated() {
            let index = offset + 1
            await progress("Preparing source \(index) of \(capped.count)…")

            guard let sourceID = source.id,
                  let url = URL(string: source.url)
            else {
                failures.append("Source \(index): invalid URL")
                continue
            }

            let sourceURL = URL(string: source.sourceURL) ?? url

            do {
                let material: VenueDealSourceMaterial
                switch source.type {
                case .image:
                    let pngData = try await prepareImage(url: url)
                    material = VenueDealSourceMaterial(
                        index: index,
                        dealSourceId: sourceID,
                        url: url,
                        sourceURL: sourceURL,
                        type: source.type,
                        pngData: pngData,
                        markdown: nil
                    )
                case .webpage:
                    material = try await prepareWebpage(
                        at: url,
                        sourceURL: sourceURL,
                        dealSourceId: sourceID,
                        index: index
                    )
                case .pdf:
                    material = try await preparePDF(
                        at: url,
                        sourceURL: sourceURL,
                        dealSourceId: sourceID,
                        index: index
                    )
                }

                materials.append(material)
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
            pngData: pngData,
            markdown: nil
        )
    }

    func prepareRemoteURL(at url: URL) -> VenueDealSourceMaterial {
        return VenueDealSourceMaterial(
            index: 1,
            dealSourceId: 0,
            url: url,
            sourceURL: url,
            type: Self.isImageURL(url) ? .image : .webpage,
            pngData: nil,
            markdown: nil
        )
    }

    func preparePDF(
        at url: URL,
        sourceURL: URL? = nil,
        dealSourceId: Int64 = 0,
        index: Int = 1
    ) async throws -> VenueDealSourceMaterial {
        let hash = URLNormalizer.hash(url)
        let localURL = try await pdfFetcher.localFileURL(for: url, hash: hash)
        guard let extraction = pdfTextExtractor.extractText(from: localURL) else {
            throw VenueDealSourceMaterialPreparerError.missingPDFText
        }

        return VenueDealSourceMaterial(
            index: index,
            dealSourceId: dealSourceId,
            url: url,
            sourceURL: sourceURL ?? url,
            type: .pdf,
            pngData: nil,
            markdown: extraction.filteredText
        )
    }

    func prepareWebpage(
        at url: URL,
        sourceURL: URL? = nil,
        dealSourceId: Int64 = 0,
        index: Int = 1
    ) async throws -> VenueDealSourceMaterial {
        let page = try await webPageLoader.load(url: url)
        guard let markdown = page.markdown,
              !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw VenueDealSourceMaterialPreparerError.missingMarkdown
        }

        return VenueDealSourceMaterial(
            index: index,
            dealSourceId: dealSourceId,
            url: page.normalizedURL,
            sourceURL: sourceURL ?? page.normalizedURL,
            type: .webpage,
            pngData: nil,
            markdown: markdown
        )
    }

    static func isRemoteURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    static func isImageURL(_ url: URL) -> Bool {
        if url.isFileURL {
            guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
            return type.conforms(to: .image)
        }

        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }

    private func prepareImage(url: URL) async throws -> Data {
        let hash = URLNormalizer.hash(url)
        let localURL = try await imageFetcher.localFileURL(for: url, hash: hash)
        return try ImagePNGConverter.pngData(from: localURL)
    }
}
