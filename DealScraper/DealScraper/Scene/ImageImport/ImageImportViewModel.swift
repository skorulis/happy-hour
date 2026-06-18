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
        case completed(deals: [DealWithSchedules], sourceURL: URL, duration: TimeInterval, markdown: String?)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    var inputMode: InputMode = .image
    var sourceURLString: String = ""
    var extractionProvider: VenueDealExtractionProvider = .openRouter
    var openAIModel: String = LLMModelStore.defaultOpenAIModel {
        didSet { llmModelStore.openAIModel = openAIModel }
    }
    var openRouterModel: String = LLMModelStore.defaultOpenRouterModel {
        didSet { llmModelStore.openRouterModel = openRouterModel }
    }

    private let venueDealExtractionService: VenueDealExtractionService
    private let webMarkdownGenerator: WebMarkdownGenerator
    private let apiKeyStore: APIKeyStore
    private let llmModelStore: LLMModelStore

    @Resolvable<Resolver>
    init(
        venueDealExtractionService: VenueDealExtractionService,
        webMarkdownGenerator: WebMarkdownGenerator,
        apiKeyStore: APIKeyStore,
        llmModelStore: LLMModelStore
    ) {
        self.venueDealExtractionService = venueDealExtractionService
        self.webMarkdownGenerator = webMarkdownGenerator
        self.apiKeyStore = apiKeyStore
        self.llmModelStore = llmModelStore
        openAIModel = llmModelStore.openAIModel
        openRouterModel = llmModelStore.openRouterModel
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
        updateState(.idle)
    }

    private func processLocalImage(at url: URL) async {
        let startTime = Date()
        updateState(.processing(progress: "Preparing image…"))

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let extractionProgress = ProgressMonitor<[DealWithSchedules]> { newValue in
                if case let .inProgress(progress) = newValue {
                    self.state = .processing(progress: progress)
                }
            }

            let deals = try await venueDealExtractionService.extractDealsFromDroppedImage(
                at: url,
                provider: extractionProvider,
                progress: extractionProgress
            )
            updateState(.completed(
                deals: deals,
                sourceURL: url,
                duration: Date().timeIntervalSince(startTime),
                markdown: nil
            ))
        } catch {
            updateState(.failed(message: error.localizedDescription))
        }
    }

    private func processRemoteURL(at url: URL) async {
        let startTime = Date()
        if VenueDealSourceMaterialPreparer.isImageURL(url) {
            updateState(.processing(progress: "Analyzing with \(extractionProvider.rawValue)…"))
        } else {
            updateState(.processing(progress: "Preparing source…"))
        }

        do {
            let extractionProgress = ProgressMonitor<[DealWithSchedules]> { newValue in
                if case let .inProgress(progress) = newValue {
                    self.state = .processing(progress: progress)
                }
            }

            async let deals = venueDealExtractionService.extractDealsFromRemoteURL(
                at: url,
                provider: extractionProvider,
                progress: extractionProgress
            )
            async let markdown = fetchMarkdown(for: url)

            updateState(.completed(
                deals: try await deals,
                sourceURL: url,
                duration: Date().timeIntervalSince(startTime),
                markdown: await markdown
            ))
        } catch {
            updateState(.failed(message: error.localizedDescription))
        }
    }

    private func fetchMarkdown(for url: URL) async -> String? {
        guard !VenueDealSourceMaterialPreparer.isImageURL(url) else { return nil }
        return try? await webMarkdownGenerator.markdown(
            for: url,
            apiKey: apiKeyStore.markdownerAPIKey
        )
    }

    private func updateState(_ state: State) {
        Task { @MainActor in
            self.state = state
        }
    }
}
