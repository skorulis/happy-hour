//Created by Alexander Skorulis on 15/6/2026.

import CoreGraphics
import Foundation

enum RelativeTextSize: String, Sendable {
    case large
    case medium
    case small
}

/// A line of text extracted from an image, with size metadata derived from Vision bounding boxes.
nonisolated struct ExtractedTextLine: Sendable {
    let text: String
    /// Max fragment height on this line, normalized 0–1 relative to image height.
    let lineHeight: CGFloat
    let relativeSize: RelativeTextSize
}
