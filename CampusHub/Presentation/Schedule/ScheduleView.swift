import SwiftUI

struct ScheduleView: View {
    @Bindable var viewModel: ScheduleViewModel

    var body: some View {
        content
            .navigationTitle("Horário")
            .searchable(text: $viewModel.searchText, prompt: "UC, professor ou turma")
            .toolbar { weekdayFilter }
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
            ProgressView("A carregar horário…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                "Sem aulas alocadas",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Quando a secretaria criar alocações, elas aparecem aqui.")
            )

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

        case .loaded:
            scheduleList
        }
    }

    private var scheduleList: some View {
        List {
            ForEach(viewModel.entriesByDay, id: \.day) { group in
                Section(group.day.name) {
                    ForEach(group.entries) { entry in
                        NavigationLink(value: entry.id) {
                            ScheduleRow(entry: entry)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: String.self) { entryID in
            if let entry = viewModel.filteredEntries.first(where: { $0.id == entryID }) {
                LessonDetailView(entry: entry)
            }
        }
        .overlay {
            if viewModel.filteredEntries.isEmpty {
                ContentUnavailableView.search
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var weekdayFilter: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Dia da semana", selection: $viewModel.selectedWeekday) {
                    Text("Todos os dias").tag(Weekday?.none)
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Text(day.name).tag(Optional(day))
                    }
                }
            } label: {
                Label(
                    "Filtrar por dia",
                    systemImage: viewModel.selectedWeekday == nil
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
            }
        }
    }
}

private struct ScheduleRow: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.unit.name)
                .font(.headline)
            Text("\(entry.timeRange) · Sala \(entry.room) · \(entry.classGroup)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.professor.name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
