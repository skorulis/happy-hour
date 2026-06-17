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
        case processing(progress: String)
        case completed(deals: [DealWithSchedules], imageURL: URL)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    var extractionProvider: VenueDealExtractionProvider = .cursor
    var cursorModel: String = "composer-2.5"

    private let venueDealExtractionService: VenueDealExtractionService

    @Resolvable<Resolver>
    init(venueDealExtractionService: VenueDealExtractionService) {
        self.venueDealExtractionService = venueDealExtractionService
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
        state = .processing(progress: "Preparing image…")

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let deals = try await venueDealExtractionService.extractDealsFromDroppedImage(
                at: url,
                provider: extractionProvider,
                model: cursorModel
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .processing(progress: progress)
                }
            }
            state = .completed(deals: deals, imageURL: url)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
