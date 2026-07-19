// Created by Alexander Skorulis on 19/7/2026.

import ASKCore
import Knit
import SwiftUI

struct SuburbListView: View {

    @State var viewModel: SuburbListViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 720, minHeight: 400)
        .onAppear {
            viewModel.loadSuburbs()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField

            Text(suburbCountLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            if case let .failed(message) = viewModel.state {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            if viewModel.suburbs.isEmpty {
                ContentUnavailableView(
                    "No Suburbs",
                    systemImage: "building.2",
                    description: Text("Import suburbs to see them listed here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredSuburbs.isEmpty {
                ContentUnavailableView(
                    "No Matching Suburbs",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different name or postcode.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedSuburbId) {
                    ForEach(viewModel.filteredSuburbs, id: \.id) { suburb in
                        suburbRow(suburb)
                            .tag(suburb.id)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Suburbs")
        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
    }

    @ViewBuilder
    private var detail: some View {
        if let suburb = viewModel.selectedSuburb {
            SuburbDetailView(
                suburb: suburb,
                countryName: viewModel.selectedCountryName,
                venues: viewModel.venues,
                actionMessage: viewModel.actionMessage,
                onCrawl: { viewModel.crawlSelectedSuburb() }
            )
            .id(suburb.id)
        } else {
            ContentUnavailableView(
                "Select a Suburb",
                systemImage: "building.2",
                description: Text("Choose a suburb from the list to view its venues.")
            )
        }
    }

    private var searchField: some View {
        TextField("Filter suburbs", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 16)
            .padding(.top, 16)
    }

    private var suburbCountLabel: String {
        let total = viewModel.suburbs.count
        let filtered = viewModel.filteredSuburbs.count
        let isFiltering = !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isFiltering {
            return "\(filtered) of \(total) suburb\(total == 1 ? "" : "s")"
        }
        return "\(total) suburb\(total == 1 ? "" : "s")"
    }

    @ViewBuilder
    private func suburbRow(_ suburb: Suburb) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(SuburbListViewModel.displayName(for: suburb))

            if let lastCrawlDate = suburb.lastCrawlDate {
                Text("Crawled \(lastCrawlDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Never crawled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    SuburbListView(viewModel: assembler.resolver.suburbListViewModel())
}
