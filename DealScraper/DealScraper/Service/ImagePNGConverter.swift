//Created by Alex Skorulis on 17/6/2026.

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImagePNGConverter {

    enum Error: Swift.Error {
        case invalidImage
        case conversionFailed
    }

    nonisolated static func pngData(from url: URL) throws -> Data {
        if let data = try? pngDataFromFile(url) {
            return data
        }
        throw Error.invalidImage
    }

    nonisolated static func pngData(from imageData: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw Error.invalidImage
        }
        return try pngData(from: cgImage)
    }

    nonisolated static func pngData(from nsImage: NSImage) throws -> Data {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw Error.invalidImage
        }
        return try pngData(from: cgImage)
    }

    private nonisolated static func pngDataFromFile(_ url: URL) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw Error.invalidImage
        }

        if let type = CGImageSourceGetType(source) as String?,
           type == UTType.png.identifier,
           let data = try? Data(contentsOf: url),
           !data.isEmpty
        {
            return data
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw Error.invalidImage
        }
        return try pngData(from: cgImage)
    }

    private nonisolated static func pngData(from cgImage: CGImage) throws -> Data {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw Error.conversionFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw Error.conversionFailed
        }
        return mutableData as Data
    }
}
