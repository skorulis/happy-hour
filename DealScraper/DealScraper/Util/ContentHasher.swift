//Created by Alex Skorulis on 25/6/2026.

import CryptoKit
import Foundation

enum ContentHasher {

    static func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func hash(fileURL: URL) throws -> String {
        try hash(Data(contentsOf: fileURL))
    }
}
