//Created by Alex Skorulis on 18/6/2026.

import Foundation
import SwiftUI

struct DealSourceRow: View {
    let source: DealSource
    let onStatusChange: (DealStatus) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            maybeImage

            VStack(alignment: .leading, spacing: 8) {
                sourceLink

                HStack(spacing: 16) {
                    Label(source.type.rawValue.capitalized, systemImage: typeIcon)
                    Text(source.date.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let preview = textPreview {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                statusButton(
                    systemImage: "checkmark",
                    color: .green,
                    isSelected: source.status == .approved
                ) {
                    onStatusChange(.approved)
                }

                statusButton(
                    systemImage: "xmark",
                    color: .red,
                    isSelected: source.status == .rejected
                ) {
                    onStatusChange(.rejected)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    @ViewBuilder
    private var sourceLink: some View {
        if let url = URL(string: source.sourceURL) {
            Link(url.lastPathComponent, destination: url)
                .lineLimit(2)
        } else {
            Text(source.sourceURL)
                .lineLimit(2)
        }
    }

    private func statusButton(
        systemImage: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(isSelected ? color : .clear)
                }
                .overlay {
                    Circle()
                        .strokeBorder(color, lineWidth: 1.5)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var maybeImage: some View {
        if source.type == .image,
           !source.url.isEmpty,
           let imageURL = URL(string: source.url) {
            Link(destination: imageURL) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: 200, maxHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Open image in browser")
        }
    }

    private var typeIcon: String {
        switch source.type {
        case .image:
            return "photo"
        case .webpage:
            return "globe"
        case .pdf:
            return "doc.fill"
        }
    }

    private var textPreview: String? {
        guard let textPieces = source.textPieces else { return nil }

        switch textPieces {
        case let .textLines(lines):
            let preview = lines.prefix(3).joined(separator: "\n")
            return preview.isEmpty ? nil : preview
        case let .contentBlocks(blocks):
            if let first = blocks.first {
                let text = first.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    return text
                }
            }
            return blocks.isEmpty ? nil : "\(blocks.count) content block\(blocks.count == 1 ? "" : "s")"
        }
    }
}
