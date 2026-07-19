// Created by Alexander Skorulis on 19/7/2026.

import SwiftUI

struct HeroImagePickerView: View {

    let imageURL: String?
    let canClear: Bool
    let onClear: () -> Void
    let onSetURL: (String) async -> Void

    @State private var showHeroImageURLPrompt = false
    @State private var heroImageURLString = ""

    var body: some View {
        heroImageView
            .alert("Hero Image URL", isPresented: $showHeroImageURLPrompt) {
                TextField("URL", text: $heroImageURLString)
                Button("Cancel", role: .cancel) {
                    heroImageURLString = ""
                }
                Button("Save") {
                    let urlString = heroImageURLString
                    heroImageURLString = ""
                    Task {
                        await onSetURL(urlString)
                    }
                }
                .disabled(!isValidHeroImageURL(heroImageURLString))
            } message: {
                Text("Enter the URL for the hero image.")
            }
    }

    @ViewBuilder
    private var heroImageView: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        if let heroImageURL = imageURL.flatMap({ URL(string: $0) }) {
            Link(destination: heroImageURL) {
                Color.clear
                    .aspectRatio(3 / 2, contentMode: .fill)
                    .frame(maxWidth: 200)
                    .overlay {
                        AsyncImage(url: heroImageURL) { phase in
                            switch phase {
                            case .empty:
                                heroImagePlaceholder
                                    .overlay { ProgressView() }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                heroImagePlaceholder
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .clipShape(shape)
            }
            .buttonStyle(.plain)
            .help("Open image in browser")
            .overlay(alignment: .topTrailing) {
                if canClear {
                    Button(action: onClear) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                }
            }
        } else {
            heroImagePlaceholder
                .aspectRatio(3 / 2, contentMode: .fit)
                .frame(maxWidth: 200)
                .overlay {
                    Button {
                        heroImageURLString = ""
                        showHeroImageURLPrompt = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
        }
    }

    private func isValidHeroImageURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            return false
        }
        return true
    }

    private var heroImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
                Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
            )
    }
}
