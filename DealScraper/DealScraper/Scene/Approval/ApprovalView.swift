//Created by Alex Skorulis on 19/6/2026.

import Knit
import SwiftUI

struct ApprovalView: View {

    @State var viewModel: ApprovalViewModel
    var onOpenInExperiment: () -> Void

    init(viewModel: ApprovalViewModel, onOpenInExperiment: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenInExperiment = onOpenInExperiment
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $viewModel.mode) {
                ForEach(ApprovalViewModel.Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(16)
            .onChange(of: viewModel.mode) {
                viewModel.onModeChanged()
            }

            Divider()

            Group {
                if viewModel.hasPendingItems {
                    reviewContent
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 560)
        .onAppear {
            viewModel.load()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "All Caught Up",
            systemImage: "checkmark.seal",
            description: Text(emptyStateMessage)
        )
    }

    private var emptyStateMessage: String {
        switch viewModel.mode {
        case .sources:
            return "No deal sources are waiting for approval."
        case .deals:
            return "No deals are waiting for approval."
        }
    }

    @ViewBuilder
    private var reviewContent: some View {
        switch viewModel.mode {
        case .sources:
            sourceReviewContent
        case .deals:
            dealReviewContent
        }
    }

    private var sourceReviewContent: some View {
        VStack(spacing: 0) {
            sourceHeader
                .padding(16)

            Divider()

            sourcePreviewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            sourceActionBar
                .padding(24)
        }
    }

    private var dealReviewContent: some View {
        VStack(spacing: 0) {
            dealHeader
                .padding(16)

            Divider()

            dealPreviewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            dealActionBar
                .padding(24)
        }
    }

    @ViewBuilder
    private var sourceHeader: some View {
        if let source = viewModel.currentSource {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.venueNames[source.venueId] ?? "Unknown Venue")
                        .font(.headline)

                    Spacer()

                    Text("\(viewModel.remainingCount) remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Label(source.type.rawValue.capitalized, systemImage: typeIcon(for: source.type))
                    Text(source.date.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let url = URL(string: source.sourceURL) {
                    Link(url.absoluteString, destination: url)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var dealHeader: some View {
        if let item = viewModel.currentDeal {
            HStack {
                Text(viewModel.venueNames[item.deal.venueId] ?? "Unknown Venue")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.remainingCount) remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var sourcePreviewSection: some View {
        switch viewModel.previewState {
        case .idle, .loading:
            ProgressView("Loading preview…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .ready(content):
            DealSourcePreviewView(content: content)
                .padding(8)

        case let .failed(message):
            VStack(spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                if let source = viewModel.currentSource,
                   let url = URL(string: source.sourceURL) {
                    Link("Open source in browser", destination: url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var dealPreviewSection: some View {
        if let item = viewModel.currentDeal {
            ScrollView {
                HStack(alignment: .top, spacing: 16) {
                    dealImage(for: item)

                    VStack(alignment: .leading, spacing: 16) {
                        editableField(label: "Title") {
                            TextField("Title", text: $viewModel.editTitle)
                                .textFieldStyle(.roundedBorder)
                        }

                        editableField(label: "Details") {
                            TextEditor(text: $viewModel.editDetails)
                                .font(.body)
                                .frame(minHeight: 100)
                                .padding(4)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.secondary.opacity(0.3))
                                }
                        }

                        editableField(label: "Conditions") {
                            TextEditor(text: $viewModel.editConditions)
                                .font(.caption)
                                .frame(minHeight: 60)
                                .padding(4)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.secondary.opacity(0.3))
                                }
                        }

                        if !viewModel.editSchedules.isEmpty {
                            editableField(label: "Schedule") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewModel.formattedEditScheduleSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ForEach($viewModel.editSchedules) { $schedule in
                                        scheduleEditRow(schedule: $schedule)
                                    }
                                }
                            }
                        }

                        dealSourceLinks(for: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
    }

    private func scheduleEditRow(schedule: Binding<EditableDealSchedule>) -> some View {
        HStack(spacing: 8) {
            Picker("Day", selection: schedule.dayOfWeek) {
                ForEach(DealScheduleFormatting.weekdaysInDisplayOrder, id: \.self) { weekday in
                    Text(DealScheduleFormatting.dayName(for: weekday))
                        .tag(weekday)
                }
            }
            .frame(width: 88)
            .labelsHidden()

            DatePicker(
                "Start",
                selection: Binding(
                    get: { DealScheduleFormatting.date(fromMinutes: schedule.wrappedValue.startMinute) },
                    set: { schedule.wrappedValue.startMinute = DealScheduleFormatting.minutes(from: $0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .frame(width: 90)

            Text("–")
                .foregroundStyle(.secondary)

            DatePicker(
                "End",
                selection: Binding(
                    get: { DealScheduleFormatting.date(fromMinutes: schedule.wrappedValue.endMinute) },
                    set: { schedule.wrappedValue.endMinute = DealScheduleFormatting.minutes(from: $0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .frame(width: 90)

            Button {
                viewModel.removeEditSchedule(id: schedule.wrappedValue.id)
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove schedule")
        }
        .font(.caption)
    }

    private func editableField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func dealImage(for item: DealWithSchedules) -> some View {
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
                        .frame(maxWidth: 200, maxHeight: 120)
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

    @ViewBuilder
    private func dealSourceLinks(for item: DealWithSchedules) -> some View {
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

    private var sourceActionBar: some View {
        HStack(spacing: 32) {
            statusButton(
                systemImage: "flask",
                color: .accentColor,
                action: {
                    viewModel.sendToExperiment()
                    onOpenInExperiment()
                }
            )
            .disabled(viewModel.currentSourceURL == nil)

            statusButton(
                systemImage: "checkmark",
                color: .green,
                action: { viewModel.decide(status: .approved) }
            )

            statusButton(
                systemImage: "xmark",
                color: .red,
                action: { viewModel.decide(status: .rejected) }
            )
        }
        .frame(maxWidth: .infinity)
        .disabled(viewModel.previewState == .loading)
    }

    private var dealActionBar: some View {
        HStack(spacing: 32) {
            statusButton(
                systemImage: "checkmark",
                color: .green,
                action: { viewModel.decideDeal(status: .approved) }
            )

            statusButton(
                systemImage: "xmark",
                color: .red,
                action: { viewModel.decideDeal(status: .rejected) }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func statusButton(
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(.clear)
                }
                .overlay {
                    Circle()
                        .strokeBorder(color, lineWidth: 2)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(for type: DealSourceType) -> String {
        switch type {
        case .image:
            return "photo"
        case .webpage:
            return "globe"
        case .pdf:
            return "doc.fill"
        }
    }
}

#Preview {
    ApprovalView(viewModel: DealScraperAssembly.testing().resolver.approvalViewModel())
}
