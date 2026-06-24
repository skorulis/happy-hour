//Created by Alex Skorulis on 25/6/2026.

import SwiftUI

struct EditableDealSchedule: Identifiable, Sendable {
    let id: Int64
    let dealId: Int64
    var dayOfWeek: Int
    var startMinute: Int
    var endMinute: Int

    init(schedule: DealSchedule, fallbackID: Int64) {
        id = schedule.id ?? fallbackID
        dealId = schedule.dealId
        dayOfWeek = schedule.dayOfWeek
        startMinute = schedule.startMinute
        endMinute = schedule.endMinute
    }

    func toDealSchedule() -> DealSchedule {
        DealSchedule(
            id: id,
            dealId: dealId,
            dayOfWeek: dayOfWeek,
            startMinute: startMinute,
            endMinute: endMinute
        )
    }
}

struct EditDealDraft: Sendable {
    var title: String
    var details: String
    var conditions: String
    var schedules: [EditableDealSchedule]
}

struct EditDealView: View {
    let item: DealWithSchedules
    var venueName: String = "Unknown Venue"
    var remainingCount: Int?
    var onAction: (DealStatus, EditDealDraft) -> Void

    @State private var title = ""
    @State private var details = ""
    @State private var conditions = ""
    @State private var schedules: [EditableDealSchedule] = []

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(16)

            Divider()

            previewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            actionBar
                .padding(24)
        }
        .onAppear {
            syncFieldsFromItem()
        }
    }

    private var header: some View {
        HStack {
            Text(venueName)
                .font(.headline)

            Spacer()

            if let remainingCount {
                Text("\(remainingCount) remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewSection: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                dealImage

                VStack(alignment: .leading, spacing: 16) {
                    editableField(label: "Title") {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    editableField(label: "Details") {
                        TextEditor(text: $details)
                            .font(.body)
                            .frame(minHeight: 100)
                            .padding(4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            }
                    }

                    editableField(label: "Conditions") {
                        TextEditor(text: $conditions)
                            .font(.caption)
                            .frame(minHeight: 60)
                            .padding(4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.secondary.opacity(0.3))
                            }
                    }

                    if !schedules.isEmpty {
                        editableField(label: "Schedule") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formattedScheduleSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach($schedules) { $schedule in
                                    scheduleEditRow(schedule: $schedule)
                                }
                            }
                        }
                    }

                    dealSourceLinks
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 32) {
            statusButton(
                systemImage: "checkmark",
                color: .green,
                action: { onAction(.approved, currentDraft) }
            )

            statusButton(
                systemImage: "xmark",
                color: .red,
                action: { onAction(.rejected, currentDraft) }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var currentDraft: EditDealDraft {
        EditDealDraft(
            title: title,
            details: details,
            conditions: conditions,
            schedules: schedules
        )
    }

    private var formattedScheduleSummary: String {
        DealScheduleFormatting.formattedSummary(schedules.map { $0.toDealSchedule() })
    }

    private func syncFieldsFromItem() {
        title = item.deal.title ?? ""
        details = item.deal.details ?? ""
        conditions = item.deal.conditions ?? ""
        schedules = DealScheduleFormatting
            .sortedSchedules(item.schedules)
            .enumerated()
            .map { index, schedule in
                EditableDealSchedule(schedule: schedule, fallbackID: Int64(-index - 1))
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
                schedules.removeAll { $0.id == schedule.wrappedValue.id }
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
    private var dealImage: some View {
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
    private var dealSourceLinks: some View {
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
}

#Preview {
    EditDealView(
        item: DealWithSchedules(
            deal: Deal(
                id: 1,
                venueId: 1,
                title: "Happy Hour",
                details: "$5 beers",
                conditions: "Bar only",
                status: .new
            ),
            schedules: [
                DealSchedule(id: 1, dealId: 1, dayOfWeek: 2, startMinute: 960, endMinute: 1140)
            ]
        ),
        venueName: "The Local",
        remainingCount: 3
    ) { _, _ in }
}
