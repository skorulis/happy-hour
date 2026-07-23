// Created by Alexander Skorulis on 19/7/2026.

import ASKCoordinator
import ASKCore
import Knit
import SwiftUI

struct SuburbListView: View {

    @Environment(\.resolver) private var resolver
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
            listModePicker

            if viewModel.listMode == .suburbs {
                searchField
            }

            Text(countLabel)
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

            listContent
        }
        .navigationTitle(viewModel.listMode == .suburbs ? "Suburbs" : "Regions")
        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
    }

    private var listModePicker: some View {
        Picker("List mode", selection: $viewModel.listMode) {
            Text("Suburbs").tag(SuburbListViewModel.ListMode.suburbs)
            Text("Regions").tag(SuburbListViewModel.ListMode.regions)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.listMode {
        case .suburbs:
            suburbListContent
        case .regions:
            regionListContent
        }
    }

    @ViewBuilder
    private var suburbListContent: some View {
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

    @ViewBuilder
    private var regionListContent: some View {
        if viewModel.regions.isEmpty {
            ContentUnavailableView(
                "No Regions",
                systemImage: "map",
                description: Text("No geographic regions are available.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $viewModel.selectedRegionId) {
                ForEach(viewModel.regions, id: \.id) { region in
                    regionRow(region)
                        .tag(region.id)
                }
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch viewModel.listMode {
        case .suburbs:
            if let suburbId = viewModel.selectedSuburbId {
                CoordinatorView(coordinator: .init(root: MainPath.suburbDetails(suburbId)))
                    .withRenderers(resolver: resolver!)
                    .id(suburbId)
            } else {
                ContentUnavailableView(
                    "Select a Suburb",
                    systemImage: "building.2",
                    description: Text("Choose a suburb from the list to view its venues.")
                )
            }
        case .regions:
            if let regionId = viewModel.selectedRegionId {
                CoordinatorView(coordinator: .init(root: MainPath.regionDetails(regionId)))
                    .withRenderers(resolver: resolver!)
                    .id(regionId)
            } else {
                ContentUnavailableView(
                    "Select a Region",
                    systemImage: "map",
                    description: Text("Choose a region from the list to view its details.")
                )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("Filter suburbs", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)

            Picker("Region", selection: $viewModel.selectedRegionFilter) {
                Text("Any region").tag(SuburbListViewModel.RegionFilter.any)
                Text("No region").tag(SuburbListViewModel.RegionFilter.none)
                ForEach(viewModel.regions, id: \.id) { region in
                    if let regionId = region.id {
                        Text(region.name).tag(SuburbListViewModel.RegionFilter.region(regionId))
                    }
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var countLabel: String {
        switch viewModel.listMode {
        case .suburbs:
            let total = viewModel.suburbs.count
            let filtered = viewModel.filteredSuburbs.count
            let hasSearch = !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let isFiltering = hasSearch || viewModel.selectedRegionFilter != .any
            if isFiltering {
                return "\(filtered) of \(total) suburb\(total == 1 ? "" : "s")"
            }
            return "\(total) suburb\(total == 1 ? "" : "s")"
        case .regions:
            let total = viewModel.regions.count
            return "\(total) region\(total == 1 ? "" : "s")"
        }
    }

    @ViewBuilder
    private func suburbRow(_ suburb: Suburb) -> some View {
        let venueCount = viewModel.venueCount(for: suburb)
        VStack(alignment: .leading, spacing: 2) {
            Text(SuburbListViewModel.displayName(for: suburb))

            Text("\(venueCount) venue\(venueCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

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

    @ViewBuilder
    private func regionRow(_ region: GeographicRegion) -> some View {
        let suburbCount = viewModel.suburbCount(for: region)
        VStack(alignment: .leading, spacing: 2) {
            Text(region.name)

            Text("\(suburbCount) suburb\(suburbCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    SuburbListView(viewModel: assembler.resolver.suburbListViewModel())
}
