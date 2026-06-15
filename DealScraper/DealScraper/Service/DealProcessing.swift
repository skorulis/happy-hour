//Created by Alex Skorulis on 15/6/2026.

import Foundation

protocol DealProcessing: Sendable {
    func extractDeals(from url: URL) async throws -> [Deal]
}
