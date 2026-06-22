//Created by Alex Skorulis on 22/6/2026.

import Knit
import SwiftUI

struct JobQueueView: View {

    @State var viewModel: JobQueueViewModel

    var body: some View {
        Group {
            if viewModel.jobs.isEmpty {
                ContentUnavailableView(
                    "No Jobs",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Queued crawl and extraction jobs will appear here.")
                )
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
        .navigationTitle("Jobs")
    }

    private var currentJobs: [JobItem] {
        viewModel.jobs.filter(\.status.isActive)
    }

    private var completedJobs: [JobItem] {
        viewModel.jobs.filter { !$0.status.isActive }
    }

    private func jobRow(for job: JobItem) -> some View {
        JobRow(
            job: job,
            venueName: viewModel.venueName(for: job.venueId),
            canCancel: viewModel.canCancel(job),
            onCancel: { viewModel.cancel(job: job) }
        )
    }
}

private struct JobRow: View {
    let job: JobItem
    let venueName: String
    let canCancel: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(venueName)
                        .font(.headline)
                    Text("\(job.type.displayLabel) · Venue #\(job.venueId)")
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
