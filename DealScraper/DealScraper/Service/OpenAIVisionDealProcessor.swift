//Created by Alex Skorulis on 15/6/2026.

import Foundation

final class OpenAIVisionDealProcessor: DealProcessing, @unchecked Sendable {

    typealias Error = RemoteVisionDealProcessorError

    nonisolated(unsafe) var apiKey: String = ""

    private let client: OpenAIClient

    nonisolated init(client: OpenAIClient) {
        self.client = client
    }

    nonisolated func extractDeals(from url: URL) async throws -> [LegacyDeal] {
        guard !apiKey.isEmpty else {
            throw Error.missingAPIKey
        }

        guard let imageData = try? Data(contentsOf: url),
              !imageData.isEmpty,
              let mimeType = VisionDealImageSupport.mimeType(for: url)
        else {
            throw Error.invalidImage
        }

        let imageBase64 = imageData.base64EncodedString()

        let payload: DealExtractionPayload
        do {
            payload = try await client.extractDeals(
                imageBase64: imageBase64,
                mimeType: mimeType,
                apiKey: apiKey,
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
