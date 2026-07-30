import Foundation
import Observation

@MainActor
@Observable
final class ScheduleViewModel {
    private let repository: any ScheduleRepositoryProtocol

    private(set) var state: ViewState<[ScheduleEntry]> = .idle
    var searchText = ""
    var selectedWeekday: Weekday?

    init(repository: any ScheduleRepositoryProtocol) {
        self.repository = repository
    }

    /// Entradas visíveis após aplicar filtro de dia e pesquisa por texto.
    var filteredEntries: [ScheduleEntry] {
        guard case .loaded(let entries) = state else { return [] }
        return entries.filter { entry in
            let matchesDay = selectedWeekday == nil || entry.weekday == selectedWeekday
            let matchesSearch = searchText.isEmpty
                || entry.unit.name.localizedCaseInsensitiveContains(searchText)
                || entry.professor.name.localizedCaseInsensitiveContains(searchText)
                || entry.classGroup.localizedCaseInsensitiveContains(searchText)
            return matchesDay && matchesSearch
        }
    }

    /// Entradas filtradas agrupadas por dia da semana, já ordenadas.
    var entriesByDay: [(day: Weekday, entries: [ScheduleEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { $0.weekday }
        return grouped
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (day: $0.key, entries: $0.value.sorted { $0.startTime < $1.startTime }) }
    }

    func load() async {
        state = .loading
        await fetch()
    }

    /// Usado no pull-to-refresh: recarrega sem passar pelo estado .loading,
    /// mantendo a lista visível; em caso de falha preserva os dados atuais.
    func refresh() async {
        await fetch(keepingCurrentOnFailure: true)
    }

    private func fetch(keepingCurrentOnFailure: Bool = false) async {
        do {
            let entries = try await repository.loadSchedule()
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch let error as AppError {
            if !keepingCurrentOnFailure { state = .error(error.userMessage) }
        } catch {
            if !keepingCurrentOnFailure { state = .error(error.localizedDescription) }
        }
    }
}
