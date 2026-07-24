//Created by Alex Skorulis on 25/6/2026.

import ASKCore
import Knit
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

    init(
        dealId: Int64,
        id: Int64,
        dayOfWeek: Int = 2,
        startMinute: Int = 960,
        endMinute: Int = 1_080
    ) {
        self.id = id
        self.dealId = dealId
        self.dayOfWeek = dayOfWeek
        self.startMinute = startMinute
        self.endMinute = endMinute
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

struct EditableDealProduct: Identifiable, Sendable {
    let id: Int64
    let dealId: Int64
    var product: String
    var price: Double?

    init(product: DealProduct, fallbackID: Int64) {
        id = product.id ?? fallbackID
        dealId = product.dealId
        self.product = product.product
        price = product.price
    }

    init(
        dealId: Int64,
        id: Int64,
        product: String,
        price: Double? = nil
    ) {
        self.id = id
        self.dealId = dealId
        self.product = product
        self.price = price
    }

    func toDealProduct() -> DealProduct {
        DealProduct(
            id: id,
            dealId: dealId,
            product: product,
            price: price
        )
    }
}

struct EditDealDraft: Sendable {
    var title: String
    var details: String
    var conditions: String
    var sourceURL: String
    var creativeURL: String
    var startDate: Date?
    var endDate: Date?
    var schedules: [EditableDealSchedule]
    var products: [EditableDealProduct]
}

struct EditDealView: View {
    enum ActionStyle {
        case approval
        case edit
    }

    let item: DealWithSchedules
    var venueName: String = "Unknown Venue"
    var remainingCount: Int?
    var actionStyle: ActionStyle = .approval
    var onVenueTap: ((Int64) -> Void)?
    var onAction: (DealStatus, EditDealDraft) -> Void = { _, _ in }
    var onSave: ((EditDealDraft) -> Void)?
    var onCancel: (() -> Void)?

    @Environment(\.resolver) private var resolver

    @State private var title = ""
    @State private var details = ""
    @State private var conditions = ""
    @State private var sourceURL = ""
    @State private var creativeURL = ""
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var schedules: [EditableDealSchedule] = []
    @State private var products: [EditableDealProduct] = []
    @State private var isExtractingProducts = false
    @State private var extractProductsError: String?

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
            if let onVenueTap {
                Button(venueName) {
                    onVenueTap(item.deal.venueId)
                }
                .buttonStyle(.plain)
                .font(.headline)
                .help("View venue details")
            } else {
                Text(venueName)
                    .font(.headline)
            }

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

                    editableField(label: "Promotion dates") {
                        VStack(alignment: .leading, spacing: 8) {
                            optionalDateRow(label: "Start", date: $startDate)
                            optionalDateRow(label: "End", date: $endDate)
                        }
                    }

                    HStack(alignment: .top, spacing: 16) {
                        editableField(label: "Schedule") {
                            VStack(alignment: .leading, spacing: 8) {
                                if !schedules.isEmpty {
                                    Text(formattedScheduleSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach($schedules) { $schedule in
                                    scheduleEditRow(schedule: $schedule)
                                }

                                Button(action: addSchedule) {
                                    Label("Add schedule", systemImage: "plus.circle")
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                            }
                        }

                        editableField(label: "Products") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach($products) { $product in
                                    productEditRow(product: $product)
                                }

                                HStack(spacing: 12) {
                                    Button(action: addProduct) {
                                        Label("Add product", systemImage: "plus.circle")
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption)

                                    Button {
                                        Task { await extractProductsFromAPI() }
                                    } label: {
                                        if isExtractingProducts {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Label("Extract", systemImage: "wand.and.stars")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption)
                                    .disabled(isExtractingProducts)
                                    .help("Replace products using title and details")
                                }

                                if let extractProductsError {
                                    Text(extractProductsError)
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    editableURLField(label: "Source URL", text: $sourceURL, linkLabel: "Page source")
                    editableURLField(
                        label: "Creative URL",
                        text: $creativeURL,
                        linkLabel: resolvedURL(from: creativeURL).map { creativeSourceLinkLabel(for: $0) }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 32) {
            switch actionStyle {
            case .approval:
                statusButton(
                    systemImage: "checkmark",
                    color: .green,
                    help: "Approve",
                    action: { onAction(.approved, currentDraft) }
                )

                statusButton(
                    systemImage: "xmark",
                    color: .red,
                    help: "Reject",
                    action: { onAction(.rejected, currentDraft) }
                )
            case .edit:
                statusButton(
                    systemImage: "checkmark",
                    color: .green,
                    help: "Save",
                    action: { onSave?(currentDraft) }
                )

                statusButton(
                    systemImage: "xmark",
                    color: .red,
                    help: "Cancel",
                    action: { onCancel?() }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var currentDraft: EditDealDraft {
        EditDealDraft(
            title: title,
            details: details,
            conditions: conditions,
            sourceURL: sourceURL,
            creativeURL: creativeURL,
            startDate: startDate,
            endDate: endDate,
            schedules: schedules,
            products: products
        )
    }

    private var formattedScheduleSummary: String {
        DealScheduleFormatting.formattedSummary(schedules.map { $0.toDealSchedule() })
    }

    private func syncFieldsFromItem() {
        title = item.deal.title ?? ""
        details = item.deal.details ?? ""
        conditions = item.deal.conditions ?? ""
        sourceURL = item.deal.sourceURL ?? ""
        creativeURL = item.deal.creativeURL ?? ""
        startDate = item.deal.startDate
        endDate = item.deal.endDate
        schedules = DealScheduleFormatting
            .sortedSchedules(item.schedules)
            .enumerated()
            .map { index, schedule in
                EditableDealSchedule(schedule: schedule, fallbackID: Int64(-index - 1))
            }
        products = item.products
            .enumerated()
            .map { index, product in
                EditableDealProduct(product: product, fallbackID: Int64(-index - 1))
            }
    }

    private func addSchedule() {
        let dealId = item.deal.id ?? schedules.first?.dealId ?? 0
        let newID = (schedules.map(\.id).min() ?? 0) - 1
        schedules.append(EditableDealSchedule(dealId: dealId, id: newID))
    }

    private func addProduct() {
        let catalog = ProductsCatalog.productNames
        guard let defaultProduct = catalog.first(where: { name in
            !products.contains { $0.product == name }
        }) ?? catalog.first else {
            return
        }
        let dealId = item.deal.id ?? products.first?.dealId ?? schedules.first?.dealId ?? 0
        let newID = (products.map(\.id).min() ?? 0) - 1
        products.append(
            EditableDealProduct(dealId: dealId, id: newID, product: defaultProduct)
        )
    }

    @MainActor
    private func extractProductsFromAPI() async {
        guard !isExtractingProducts else { return }
        guard let resolver else {
            extractProductsError = "App services unavailable"
            return
        }

        isExtractingProducts = true
        extractProductsError = nil
        defer { isExtractingProducts = false }

        do {
            let client = resolver.extractProductsAPIClient()
            let baseURL = resolver.backendURLStore().backendURL
            let payload = try await client.extractProducts(
                baseURL: baseURL,
                title: title.isEmpty ? nil : title,
                details: details.isEmpty ? nil : details
            )

            let dealId = item.deal.id ?? products.first?.dealId ?? schedules.first?.dealId ?? 0
            products = payload.products.enumerated().map { index, extracted in
                EditableDealProduct(
                    dealId: dealId,
                    id: Int64(-index - 1),
                    product: extracted.name,
                    price: extracted.price
                )
            }
        } catch {
            extractProductsError = error.localizedDescription
        }
    }

    private func productEditRow(product: Binding<EditableDealProduct>) -> some View {
        HStack(spacing: 8) {
            Picker("Product", selection: product.product) {
                ForEach(ProductsCatalog.productNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .labelsHidden()
            .frame(minWidth: 120)

            TextField(
                "Price",
                text: Binding(
                    get: {
                        guard let price = product.wrappedValue.price else { return "" }
                        if price.rounded() == price {
                            return String(Int(price))
                        }
                        return String(price)
                    },
                    set: { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            product.wrappedValue.price = nil
                        } else {
                            product.wrappedValue.price = Double(trimmed)
                        }
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 72)

            Button {
                products.removeAll { $0.id == product.wrappedValue.id }
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove product")
        }
        .font(.caption)
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
                    set: { newDate in
                        schedule.wrappedValue.startMinute = DealScheduleFormatting.minutes(from: newDate)
                        schedule.wrappedValue.endMinute = DealScheduleFormatting.normalizedEndMinute(
                            endMinute: schedule.wrappedValue.endMinute,
                            startMinute: schedule.wrappedValue.startMinute
                        )
                    }
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
                    set: { newDate in
                        schedule.wrappedValue.endMinute = DealScheduleFormatting.endMinutes(
                            from: newDate,
                            startMinute: schedule.wrappedValue.startMinute
                        )
                    }
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

    private func optionalDateRow(label: String, date: Binding<Date?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 40, alignment: .leading)
                .foregroundStyle(.secondary)

            if date.wrappedValue != nil {
                DatePicker(
                    label,
                    selection: Binding(
                        get: { date.wrappedValue ?? Date() },
                        set: { date.wrappedValue = Calendar.current.startOfDay(for: $0) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()

                Button {
                    date.wrappedValue = nil
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Clear \(label.lowercased()) date")
            } else {
                Text("Not set")
                    .foregroundStyle(.secondary)

                Button {
                    date.wrappedValue = Calendar.current.startOfDay(for: Date())
                } label: {
                    Label("Set date", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
            }
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

    private func editableURLField(label: String, text: Binding<String>, linkLabel: String?) -> some View {
        editableField(label: label) {
            HStack(spacing: 8) {
                TextField(label, text: text)
                    .textFieldStyle(.roundedBorder)

                if let url = resolvedURL(from: text.wrappedValue), let linkLabel {
                    Link(linkLabel, destination: url)
                }
            }
            .font(.caption)
        }
    }

    private func resolvedURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    @ViewBuilder
    private var dealImage: some View {
        if let creativeURL = resolvedURL(from: creativeURL) {
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
        help: String,
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
        .help(help)
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
            ],
            products: [
                DealProduct(id: 1, dealId: 1, product: "beer", price: 5)
            ]
        ),
        venueName: "The Local",
        remainingCount: 3,
        onAction: { _, _ in }
    )
}
