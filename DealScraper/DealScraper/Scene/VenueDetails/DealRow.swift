//Created by Alex Skorulis on 18/6/2026.

import Foundation
import SwiftUI

struct DealRow: View {
    let item: DealWithSchedules
    var onStatusChange: ((DealStatus) -> Void)?

    var body: some View {
        HStack(alignment: .top) {
            maybeImage
            mainContent

            if let onStatusChange {
                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    statusButton(
                        systemImage: "checkmark",
                        color: .green,
                        isSelected: item.deal.status == .approved
                    ) {
                        onStatusChange(.approved)
                    }

                    statusButton(
                        systemImage: "xmark",
                        color: .red,
                        isSelected: item.deal.status == .rejected
                    ) {
                        onStatusChange(.rejected)
                    }
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
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = item.deal.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
            }

            if let details = item.deal.details, !details.isEmpty {
                Text(details)
                    .font(.body)
            }

            if let conditions = item.deal.conditions, !conditions.isEmpty {
                Text(conditions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !item.schedules.isEmpty {
                Text(item.formattedScheduleSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            sourceLinks
        }
    }

    @ViewBuilder
    private var sourceLinks: some View {
        HStack(spacing: 16) {
            if let sourceURL = item.deal.sourceURL, let url = URL(string: sourceURL) {
                Link("Page source", destination: url)
            }

            if let imageURLString = item.deal.imageURL,
               !imageURLString.isEmpty,
               let url = URL(string: imageURLString) {
                Link("Image source", destination: url)
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private var maybeImage: some View {
        if let imageURLString = item.deal.imageURL,
           !imageURLString.isEmpty,
           let imageURL = URL(string: imageURLString) {
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
}
