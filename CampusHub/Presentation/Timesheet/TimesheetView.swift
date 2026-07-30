import SwiftUI

struct TimesheetView: View {
    @Bindable var viewModel: TimesheetViewModel
    @State private var isAddingEntry = false

    var body: some View {
        content
            .navigationTitle("Horas letivas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingEntry = true
                    } label: {
                        Label("Registar horas", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingEntry) {
                AddTimesheetEntrySheet(viewModel: viewModel)
            }
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("A carregar registos…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView {
                Label("Sem registos", systemImage: "clock.badge.questionmark")
            } description: {
                Text("Registe as horas lecionadas para gerar o resumo mensal a enviar ao coordenador.")
            } actions: {
                Button("Registar horas") { isAddingEntry = true }
                    .buttonStyle(.borderedProminent)
            }

        case .error(let message):
            ContentUnavailableView {
                Label("Não foi possível carregar", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Tentar novamente") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }

        case .loaded(let entries):
            List {
                Section("Resumo mensal") {
                    ForEach(viewModel.monthlySummaries) { summary in
                        LabeledContent(summary.title) {
                            Text("\(summary.totalHours, specifier: "%.1f") h")
                                .bold()
                        }
                    }
                }

                Section("Registos") {
                    ForEach(entries) { entry in
                        TimesheetRow(entry: entry)
                    }
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

private struct TimesheetRow: View {
    let entry: TimesheetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.unitName)
                    .font(.headline)
                Spacer()
                Text("\(entry.hours, specifier: "%.1f") h")
                    .font(.headline)
            }
            HStack {
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.status.label)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        entry.status == .submitted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2),
                        in: Capsule()
                    )
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

private struct AddTimesheetEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TimesheetViewModel

    @State private var date = Date()
    @State private var hours = 3.0
    @State private var unitName = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Data", selection: $date, displayedComponents: .date)
                Stepper(value: $hours, in: 0.5...12, step: 0.5) {
                    Text("\(hours, specifier: "%.1f") horas")
                }
                TextField("Unidade curricular", text: $unitName)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            .navigationTitle("Registar horas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            if await viewModel.addEntry(date: date, hours: hours, unitName: unitName) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(unitName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSaving)
                }
            }
        }
    }
}
