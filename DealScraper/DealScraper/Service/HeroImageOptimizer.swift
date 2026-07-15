//Created by Alex Skorulis on 15/7/2026.

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum HeroImageOptimizer {

    static let maxWidth = 1600
    static let thumbWidth = 200
    static let jpegQuality: CGFloat = 0.82

    struct Output: Equatable {
        let full: Data
        let thumb: Data
    }

    enum Error: LocalizedError {
        case invalidImage
        case encodeFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not read the hero image."
            case .encodeFailed:
                return "Could not encode the hero image."
            }
        }
    }

    /// Resize to full (~1600px) and thumb (200px) JPEGs for CDN upload.
    static func optimize(_ data: Data) throws -> Output {
        guard let nsImage = NSImage(data: data),
              let original = cgImage(from: nsImage)
        else {
            throw Error.invalidImage
        }

        guard original.width > 0, original.height > 0 else {
            throw Error.invalidImage
        }

        let fullImage = try resized(original, maxWidth: maxWidth)
        let thumbImage = try resized(original, maxWidth: thumbWidth)

        return Output(
            full: try encodeJPEG(fullImage),
            thumb: try encodeJPEG(thumbImage)
        )
    }

    private static func cgImage(from image: NSImage) -> CGImage? {
        var rect = NSRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    private static func resized(_ image: CGImage, maxWidth: Int) throws -> CGImage {
        let width = image.width
        let height = image.height
        if width <= maxWidth {
            return image
        }

        let scale = CGFloat(maxWidth) / CGFloat(width)
        let targetSize = CGSize(
            width: CGFloat(maxWidth),
            height: max(1, floor(CGFloat(height) * scale))
        )
        guard let resized = resize(image, to: targetSize) else {
            throw Error.invalidImage
        }
        return resized
    }

    private static func resize(_ image: CGImage, to size: CGSize) -> CGImage? {
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        return context.makeImage()
    }

    private static func encodeJPEG(_ image: CGImage) throws -> Data {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw Error.encodeFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: jpegQuality,
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw Error.encodeFailed
        }
        return mutableData as Data
    }
}
