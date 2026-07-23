//Created by Alex Skorulis on 22/6/2026.

import ASKCoordinator
import ASKCore
import Knit
import SwiftUI

struct JobQueueView: View {

    @Environment(\.resolver) private var resolver
    @State var viewModel: JobQueueViewModel

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            jobList
        }
        .navigationTitle("Jobs")
        .onAppear {
            viewModel.loadRegions()
        }
    }

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Crawl Next") {
                    viewModel.crawlNext()
                }

                Button("Extract Next") {
                    viewModel.extractNext()
                }

                Button("Crawl Next Suburb") {
                    viewModel.crawlNextSuburb()
                }

                Spacer()

                regionPicker
            }

            if let message = viewModel.actionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var regionPicker: some View {
        Picker("Region", selection: $viewModel.selectedRegionFilter) {
            Text("Any region").tag(JobQueueViewModel.RegionFilter.any)
            Text("No region").tag(JobQueueViewModel.RegionFilter.none)
            ForEach(viewModel.regions, id: \.id) { region in
                if let regionId = region.id {
                    Text(region.name).tag(JobQueueViewModel.RegionFilter.region(regionId))
                }
            }
        }
        .pickerStyle(.menu)
        .fixedSize()
    }

    @ViewBuilder
    private var jobList: some View {
        Group {
            if viewModel.jobs.isEmpty {
                VStack {
                    ContentUnavailableView(
                        "No Jobs",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Queued crawl and extraction jobs will appear here.")
                    )
                    Spacer()
                }
            } else {
                List {
                    if !currentJobs.isEmpty {
                        Section("Current") {
                            ForEach(currentJobs) { job in
                                jobRow(for: job)
                            }
                        }
                    }

                    if !completedJobs.isEmpty {
                        Section("Completed") {
                            ForEach(completedJobs) { job in
                                jobRow(for: job)
                            }
                        }
                    }
                }
            }
        }
    }

    private var currentJobs: [JobItem] {
        viewModel.jobs.filter(\.status.isActive)
    }

    private var completedJobs: [JobItem] {
        viewModel.jobs
            .filter { !$0.status.isActive }
            .sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }
    }

    @ViewBuilder
    private func jobRow(for job: JobItem) -> some View {
        let row = JobRow(
            job: job,
            title: viewModel.jobTitle(for: job),
            subtitle: viewModel.jobSubtitle(for: job),
            canCancel: viewModel.canCancel(job),
            onCancel: { viewModel.cancel(job: job) }
        )

        if let venueId = job.venueId,
           let googleMapId = viewModel.googleMapId(for: venueId)
        {
            Button(action: {
                viewModel.coordinator?.push(MainPath.venueDetails(googleMapId))
            }, label: { row })
        } else {
            row
        }
    }
}

private struct JobRow: View {
    let job: JobItem
    let title: String
    let subtitle: String
    let canCancel: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if canCancel {
                    Button("Cancel", role: .destructive, action: onCancel)
                        .buttonStyle(.borderless)
                }
            }

            statusView
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusView: some View {
        switch job.status {
        case .pending:
            Text("Queued…")
                .font(.caption)
                .foregroundStyle(.secondary)
        case let .running(progress):
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(progress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case let .completed(result):
            Text(resultSummary(result))
                .font(.caption)
                .foregroundStyle(.secondary)
        case let .failed(message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
        case .cancelled:
            Text("Cancelled")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func resultSummary(_ result: JobResult) -> String {
        switch result {
        case let .crawl(crawlResults):
            return "Found \(crawlResults.dealsFound) deal source\(crawlResults.dealsFound == 1 ? "" : "s") in \(formattedDuration(crawlResults.duration))."
        case let .extract(extractResults):
            return "Extracted \(extractResults.dealsFound) deal\(extractResults.dealsFound == 1 ? "" : "s") in \(formattedDuration(extractResults.duration))."
        case let .crawlSuburb(suburbResults):
            return "Found \(suburbResults.venuesFound) venue\(suburbResults.venuesFound == 1 ? "" : "s"), \(suburbResults.newVenues) new in \(formattedDuration(suburbResults.duration))."
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

#Preview {
    JobQueueView(viewModel: DealScraperAssembly.testing().resolver.jobQueueViewModel())
}
