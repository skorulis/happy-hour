// Created by Alexander Skorulis on 23/7/2026.

import SwiftUI

struct GeographicRegionDetailView: View {

    @State var viewModel: GeographicRegionDetailViewModel

    var body: some View {
        Group {
            if let region = viewModel.region {
                regionContent(region)
            } else {
                ContentUnavailableView(
                    "Region Not Found",
                    systemImage: "map",
                    description: Text("This region is no longer saved locally.")
                )
            }
        }
    }

    private func regionContent(_ region: GeographicRegion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(region)
            Spacer(minLength: 0)
        }
    }

    private func header(_ region: GeographicRegion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(viewModel.suburbCount) suburb\(viewModel.suburbCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(countsLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1)

                HeroImagePickerView(
                    imageURL: region.heroImage,
                    canClear: viewModel.canClearHeroImage,
                    onClear: { viewModel.clearHeroImage() },
                    onSetURL: { urlString in
                        await viewModel.setHeroImage(urlString: urlString)
                    }
                )
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var countsLabel: String {
        let venueCount = viewModel.venueCount
        let sourceCount = viewModel.sourceCount
        let dealCount = viewModel.dealCount
        let venues = "\(venueCount) venue\(venueCount == 1 ? "" : "s")"
        let sources = "\(sourceCount) source\(sourceCount == 1 ? "" : "s")"
        let deals = "\(dealCount) deal\(dealCount == 1 ? "" : "s")"
        return "\(venues) · \(sources) · \(deals)"
    }
}
