//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros
import UniformTypeIdentifiers

enum DealProcessingMode: String, CaseIterable {
    case onDevice = "On-Device"
    case visionAPI = "OpenAI"
    case openRouter = "OpenRouter"
    case cursor = "Cursor"
}

@MainActor
@Observable
final class ImageImportViewModel {

    enum State {
        case idle
        case processing
        case completed(deals: [LegacyDeal], imageURL: URL)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    var processingMode: DealProcessingMode = .onDevice
    var openRouterModel: String = "openai/gpt-4o"
    var cursorModel: String = "composer-2.5"

    private let apiKeyStore: APIKeyStore
    private let onDeviceProcessor: OnDeviceDealProcessor
    private let visionProcessor: OpenAIVisionDealProcessor
    private let openRouterProcessor: OpenRouterVisionDealProcessor
    private let cursorProcessor: CursorVisionDealProcessor

    @Resolvable<Resolver>
    init(
        apiKeyStore: APIKeyStore,
        onDeviceProcessor: OnDeviceDealProcessor,
        visionProcessor: OpenAIVisionDealProcessor,
        openRouterProcessor: OpenRouterVisionDealProcessor,
        cursorProcessor: CursorVisionDealProcessor
    ) {
        self.apiKeyStore = apiKeyStore
        self.onDeviceProcessor = onDeviceProcessor
        self.visionProcessor = visionProcessor
        self.openRouterProcessor = openRouterProcessor
        self.cursorProcessor = cursorProcessor
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
            let deals: [LegacyDeal]
            switch processingMode {
            case .onDevice:
                deals = try await onDeviceProcessor.extractDeals(from: url)
            case .visionAPI:
                let apiKey = apiKeyStore.openAIAPIKey
                guard !apiKey.isEmpty else {
                    throw RemoteVisionDealProcessorError.missingAPIKey
                }
                visionProcessor.apiKey = apiKey
                deals = try await visionProcessor.extractDeals(from: url)
            case .openRouter:
                let apiKey = apiKeyStore.openRouterAPIKey
                guard !apiKey.isEmpty else {
                    throw RemoteVisionDealProcessorError.missingAPIKey
                }
                openRouterProcessor.apiKey = apiKey
                openRouterProcessor.model = openRouterModel
                deals = try await openRouterProcessor.extractDeals(from: url)
            case .cursor:
                let apiKey = apiKeyStore.cursorAPIKey
                guard !apiKey.isEmpty else {
                    throw RemoteVisionDealProcessorError.missingAPIKey
                }
                cursorProcessor.apiKey = apiKey
                cursorProcessor.model = cursorModel
                deals = try await cursorProcessor.extractDeals(from: url)
            }
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
        case RemoteVisionDealProcessorError.missingAPIKey:
            switch processingMode {
            case .openRouter:
                return "Configure an OpenRouter API key in Settings."
            case .visionAPI:
                return "Configure an OpenAI API key in Settings."
            case .cursor:
                return "Configure a Cursor API key in Settings."
            case .onDevice:
                return "API key is required for remote processing."
            }
        case RemoteVisionDealProcessorError.missingModel:
            switch processingMode {
            case .openRouter:
                return "Enter an OpenRouter model name."
            case .cursor:
                return "Enter a Cursor model name."
            default:
                return "Enter a model name."
            }
        case RemoteVisionDealProcessorError.invalidImage:
            if processingMode == .cursor {
                return "Cursor supports PNG, JPEG, GIF, and WebP images only."
            }
            return "Could not read the image file."
        case RemoteVisionDealProcessorError.decodingFailure:
            return "Could not parse the vision model response."
        case let RemoteVisionDealProcessorError.apiError(statusCode, message):
            let provider: String
            switch processingMode {
            case .openRouter:
                provider = "OpenRouter"
            case .cursor:
                provider = "Cursor"
            default:
                provider = "OpenAI"
            }
            return "\(provider) API error (\(statusCode)): \(message)"
        case let RemoteVisionDealProcessorError.networkFailure(underlying):
            return "Network error: \(underlying.localizedDescription)"
        default:
            return error.localizedDescription
        }
    }
}
