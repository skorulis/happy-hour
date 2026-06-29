//Created by Alex Skorulis on 29/6/2026.

import Foundation

struct Product: Decodable, Equatable {
    let name: String
    let rank: Int?
    let groups: [String]?
    let hidden: Bool?
}

nonisolated enum ProductsCatalog {
    static let productNames: [String] = loadProductNames()

    static func loadProductNames(from bundle: Bundle = .dealScraper) -> [String] {
        guard let url = bundle.url(forResource: "products", withExtension: "json") else {
            fatalError("Missing products.json in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            let products = try JSONDecoder().decode([Product].self, from: data)
            return products.map(\.name)
        } catch {
            fatalError("Failed to load products.json: \(error)")
        }
    }
}

private final class BundleAnchor {}

extension Bundle {
    nonisolated static var dealScraper: Bundle {
        Bundle(for: BundleAnchor.self)
    }
}
