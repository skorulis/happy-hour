//Created by Alex Skorulis on 1/7/2026.

import Knit
import SwiftUI

struct StatsView: View {

    @State var viewModel: StatsViewModel

    var body: some View {
        Form {
            Section("Venues") {
                statRow(title: "Total venues", value: viewModel.totalVenues)
                statRow(title: "Ready venues", value: viewModel.readyVenues)
            }

            Section("Deal Sources") {
                statRow(title: "Total deal sources", value: viewModel.totalDealSources)
                statRow(title: "Accepted deal sources", value: viewModel.acceptedDealSources)
            }

            Section("Deals") {
                statRow(title: "Total deals", value: viewModel.totalDeals)
                statRow(title: "Accepted deals", value: viewModel.acceptedDeals)
            }

            Section("Coverage") {
                statRow(title: "Total suburbs", value: viewModel.totalSuburbs)
                statRow(title: "Crawled suburbs", value: viewModel.crawledSuburbs)
                statRow(title: "Suburbs with venues", value: viewModel.suburbsWithVenues)
                statRow(title: "Suburbs with deals", value: viewModel.suburbsWithDeals)
            }

            if case let .failed(message) = viewModel.state {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
        .navigationTitle("Stats")
        .onAppear {
            viewModel.load()
        }
    }

    private func statRow(title: String, value: Int) -> some View {
        LabeledContent(title) {
            Text("\(value)")
                .monospacedDigit()
        }
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    StatsView(viewModel: assembler.resolver.statsViewModel())
}
