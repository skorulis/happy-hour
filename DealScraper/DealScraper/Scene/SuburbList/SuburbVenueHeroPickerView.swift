// Created by Alexander Skorulis on 23/7/2026.

import AppKit
import SwiftUI

struct SuburbVenueHeroPickerView: View {

    let venues: [Venue]
    let onSelect: (Venue) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectingGoogleMapId: String?

    private var venuesWithHeroes: [Venue] {
        venues.filter { venue in
            guard let hero = venue.heroImage?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return !hero.isEmpty
        }
    }

    private var isSelecting: Bool {
        selectingGoogleMapId != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if venuesWithHeroes.isEmpty {
                    ContentUnavailableView(
                        "No Venue Heroes",
                        systemImage: "photo",
                        description: Text("None of the venues in this suburb have a hero image yet.")
                    )
                } else {
                    List {
                        ForEach(venuesWithHeroes, id: \.googleMapId) { venue in
                            Button {
                                select(venue)
                            } label: {
                                row(venue)
                            }
                            .buttonStyle(.plain)
                            .disabled(isSelecting)
                        }
                    }
                }
            }
            .navigationTitle("Select venue hero")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSelecting)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 480)
    }

    private func row(_ venue: Venue) -> some View {
        HStack(spacing: 12) {
            thumbnail(venue)
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .background(Color(nsColor: .controlBackgroundColor))

            Text(venue.name)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if selectingGoogleMapId == venue.googleMapId {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumbnail(_ venue: Venue) -> some View {
        if let source = venue.heroImage, let url = URL(string: source) {
            if url.isFileURL {
                localImage(url)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                    @unknown default:
                        placeholder
                    }
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private func localImage(_ url: URL) -> some View {
        if let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.title3)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func select(_ venue: Venue) {
        guard !isSelecting else { return }
        selectingGoogleMapId = venue.googleMapId
        Task {
            await onSelect(venue)
            dismiss()
        }
    }
}
