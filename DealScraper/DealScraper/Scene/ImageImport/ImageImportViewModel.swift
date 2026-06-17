//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class ImageImportViewModel {

    enum InputMode: String, CaseIterable {
        case image = "Image"
        case url = "URL"
    }

    enum State {
        case idle
        case processing(progress: String)
        case completed(deals: [DealWithSchedules], sourceURL: URL)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    var inputMode: InputMode = .image
    var sourceURLString: String = ""
    var extractionProvider: VenueDealExtractionProvider = .openAI
    var openAIModel: String = "gpt-4o"
    var openRouterModel: String = "google/gemini-2.5-pro"

    private let venueDealExtractionService: VenueDealExtractionService

    @Resolvable<Resolver>
    init(venueDealExtractionService: VenueDealExtractionService) {
        self.venueDealExtractionService = venueDealExtractionService
    }

    private var extractionModel: String {
        switch extractionProvider {
        case .openAI:
            openAIModel
        case .openRouter:
            openRouterModel
        }
    }

    static func isLocalImageURL(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        return VenueDealSourceMaterialPreparer.isImageURL(url)
    }

    func processDroppedImage(at url: URL) {
        guard Self.isLocalImageURL(url) else {
            state = .failed(message: "Please drop an image file.")
            return
        }

        Task {
            await processLocalImage(at: url)
        }
    }

    func processURL() {
        let trimmed = sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              VenueDealSourceMaterialPreparer.isRemoteURL(url)
        else {
            state = .failed(message: "Enter a valid HTTP or HTTPS URL.")
            return
        }

        Task {
            await processRemoteURL(at: url)
        }
    }

    func reset() {
        state = .idle
    }

    private func processLocalImage(at url: URL) async {
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
                model: extractionModel
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .processing(progress: progress)
                }
            }
            state = .completed(deals: deals, sourceURL: url)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func processRemoteURL(at url: URL) async {
        if VenueDealSourceMaterialPreparer.isImageURL(url) {
            state = .processing(progress: "Analyzing with \(extractionProvider.rawValue)…")
        } else {
            state = .processing(progress: "Preparing source…")
        }

        do {
            let deals = try await venueDealExtractionService.extractDealsFromRemoteURL(
                at: url,
                provider: extractionProvider,
                model: extractionModel
            ) { [unowned self] progress in
                Task { @MainActor in
                    self.state = .processing(progress: progress)
                }
            }
            state = .completed(deals: deals, sourceURL: url)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
