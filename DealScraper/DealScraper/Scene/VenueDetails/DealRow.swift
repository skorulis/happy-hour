//Created by Alex Skorulis on 18/6/2026.

import Foundation
import SwiftUI

struct DealRow: View {
    let item: DealWithSchedules
    var venueName: String = "Unknown Venue"
    var onStatusChange: ((DealStatus) -> Void)?
    var onEdit: ((EditDealDraft) -> Void)?

    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top) {
            maybeImage
            mainContent

            if onEdit != nil || onStatusChange != nil {
                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    if onEdit != nil {
                        actionButton(
                            systemImage: "pencil",
                            color: .accentColor,
                            help: "Edit"
                        ) {
                            isEditing = true
                        }
                    }

                    if let onStatusChange {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .sheet(isPresented: $isEditing) {
            EditDealView(
                item: item,
                venueName: venueName,
                actionStyle: .edit,
                onSave: { draft in
                    onEdit?(draft)
                    isEditing = false
                },
                onCancel: {
                    isEditing = false
                }
            )
            .frame(minWidth: 720, minHeight: 560)
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

            if let creativeURLString = item.deal.creativeURL,
               !creativeURLString.isEmpty,
               let url = URL(string: creativeURLString) {
                Link(creativeSourceLinkLabel(for: url), destination: url)
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private var maybeImage: some View {
        if let creativeURLString = item.deal.creativeURL,
           !creativeURLString.isEmpty,
           let creativeURL = URL(string: creativeURLString) {
            switch PageLinkFilter.sourceType(for: creativeURL) {
            case .image:
                Link(destination: creativeURL) {
                    AsyncImage(url: creativeURL) { phase in
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
            case .pdf:
                Link(destination: creativeURL) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 80, height: 120)
                        .overlay {
                            Image(systemName: "doc.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                }
                .buttonStyle(.plain)
                .help("Open PDF in browser")
            case .webpage:
                EmptyView()
            }
        }
    }

    private func creativeSourceLinkLabel(for url: URL) -> String {
        switch PageLinkFilter.sourceType(for: url) {
        case .pdf:
            return "PDF source"
        case .image:
            return "Image source"
        case .webpage:
            return "Creative source"
        }
    }

    private func actionButton(
        systemImage: String,
        color: Color,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(.clear)
                }
                .overlay {
                    Circle()
                        .strokeBorder(color, lineWidth: 1.5)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
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
