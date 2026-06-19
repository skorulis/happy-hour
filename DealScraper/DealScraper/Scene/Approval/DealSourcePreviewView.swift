//Created by Alex Skorulis on 19/6/2026.

import SwiftUI

struct DealSourcePreviewView: View {
    let content: ApprovalViewModel.PreviewContent

    var body: some View {
        switch content {
        case let .image(url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Failed to load image")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }

        case let .pdf(document):
            PDFKitView(document: document)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .webpage(url):
            WebPageView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
