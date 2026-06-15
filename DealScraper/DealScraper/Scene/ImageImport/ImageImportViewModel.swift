//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros
import UniformTypeIdentifiers

@MainActor
@Observable
final class ImageImportViewModel {

    enum State {
        case idle
        case processing
        case completed(deals: [Deal], imageURL: URL)
        case failed(message: String)
    }

    private(set) var state: State = .idle

    private let imageExtractor: DealImageExtractor
    private let textAnalyzer: DealTextAnalyzer

    @Resolvable<Resolver>
    init(
        imageExtractor: DealImageExtractor,
        textAnalyzer: DealTextAnalyzer
    ) {
        self.imageExtractor = imageExtractor
        self.textAnalyzer = textAnalyzer
    }

    static func isImageURL(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }

    func processDroppedImage(at url: URL) {
        guard Self.isImageURL(url) else {
            state = .failed(message: "Please drop an image file.")
            return
        }

        Task {
            await process(url: url)
        }
    }

    func reset() {
        state = .idle
    }

    private func process(url: URL) async {
        state = .processing

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let lines = try await imageExtractor.extractTexts(from: url)
            let deals = try await textAnalyzer.analyze(lines: lines)
            state = .completed(deals: deals, imageURL: url)
        } catch {
            state = .failed(message: localizedMessage(for: error))
        }
    }

    private func localizedMessage(for error: Error) -> String {
        switch error {
        case DealImageExtractor.Error.invalidImage:
            return "Could not read the image file."
        case DealImageExtractor.Error.recognitionFailed:
            return "Text recognition failed."
        case DealTextAnalyzer.Error.emptyInput:
            return "No text was found in the image."
        case DealTextAnalyzer.Error.modelUnavailable:
            return "On-device language model is not available."
        default:
            return error.localizedDescription
        }
    }
}
