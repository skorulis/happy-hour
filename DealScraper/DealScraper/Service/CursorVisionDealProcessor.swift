//Created by Alex Skorulis on 17/6/2026.

import Foundation

final class CursorVisionDealProcessor: DealProcessing, @unchecked Sendable {

    typealias Error = RemoteVisionDealProcessorError

    nonisolated(unsafe) var apiKey: String = ""
    nonisolated(unsafe) var model: String = ""

    private let client: CursorClient

    nonisolated init(client: CursorClient) {
        self.client = client
    }

    nonisolated func extractDeals(from url: URL) async throws -> [Deal] {
        guard !apiKey.isEmpty else {
            throw Error.missingAPIKey
        }

        guard !model.isEmpty else {
            throw Error.missingModel
        }

        guard let imageData = try? Data(contentsOf: url),
              !imageData.isEmpty,
              let mimeType = VisionDealImageSupport.mimeType(for: url)
        else {
            throw Error.invalidImage
        }

        guard CursorImageSupport.isSupported(mimeType: mimeType) else {
            throw Error.invalidImage
        }

        let imageBase64 = imageData.base64EncodedString()

        let payload: DealExtractionPayload
        do {
            payload = try await client.extractDeals(
                imageBase64: imageBase64,
                mimeType: mimeType,
                apiKey: apiKey,
                model: model,
                instructions: VisionDealInstructions.posterExtraction
            )
        } catch let error as VisionDealAPI.Error {
            throw RemoteVisionDealProcessorSupport.mapClientError(error)
        } catch {
            throw Error.networkFailure(underlying: error)
        }

        return DealMapper.map(payload.deals)
    }
}
