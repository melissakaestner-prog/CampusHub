import Testing
import Foundation
@testable import CampusHub

@MainActor
struct ScheduleViewModelTests {
    @Test("Carregamento com sucesso passa a loaded")
    func loadSuccessSetsLoaded() async {
        let repository = MockScheduleRepository()
        let entries = [Fixtures.scheduleEntry(id: "s1")]
        repository.scheduleResult = .success(entries)
        let viewModel = ScheduleViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .loaded(entries))
    }

    @Test("Lista vazia passa a empty")
    func loadEmptySetsEmpty() async {
        let repository = MockScheduleRepository()
        repository.scheduleResult = .success([])
        let viewModel = ScheduleViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("Erro passa a error com mensagem amigável")
    func loadFailureSetsError() async {
        let repository = MockScheduleRepository()
        repository.scheduleResult = .failure(.offlineWithoutCache)
        let viewModel = ScheduleViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .error(AppError.offlineWithoutCache.userMessage))
    }

    @Test("Filtro por dia da semana restringe as entradas")
    func weekdayFilterRestrictsEntries() async {
        let repository = MockScheduleRepository()
        repository.scheduleResult = .success([
            Fixtures.scheduleEntry(id: "s1", weekday: .monday),
            Fixtures.scheduleEntry(id: "s2", weekday: .tuesday),
        ])
        let viewModel = ScheduleViewModel(repository: repository)
        await viewModel.load()

        viewModel.selectedWeekday = .tuesday

        #expect(viewModel.filteredEntries.map(\.id) == ["s2"])
    }

    @Test("Pesquisa filtra por UC, professor ou turma, sem distinguir maiúsculas")
    func searchFiltersCaseInsensitively() async {
        let repository = MockScheduleRepository()
        repository.scheduleResult = .success([
            Fixtures.scheduleEntry(id: "s1", unitName: "Gestão de Projetos", classGroup: "DS-2A"),
            Fixtures.scheduleEntry(id: "s2", unitName: "Cibercultura", classGroup: "CS-1A"),
        ])
        let viewModel = ScheduleViewModel(repository: repository)
        await viewModel.load()

        viewModel.searchText = "ciber"
        #expect(viewModel.filteredEntries.map(\.id) == ["s2"])

        viewModel.searchText = "ds-2a"
        #expect(viewModel.filteredEntries.map(\.id) == ["s1"])
    }

    @Test("Refresh falhado preserva os dados atuais")
    func failedRefreshKeepsCurrentData() async {
        let repository = MockScheduleRepository()
        let entries = [Fixtures.scheduleEntry(id: "s1")]
        repository.scheduleResult = .success(entries)
        let viewModel = ScheduleViewModel(repository: repository)
        await viewModel.load()

        repository.scheduleResult = .failure(.network("timeout"))
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(entries))
    }

    @Test("Agrupamento por dia ordena por dia e hora de início")
    func groupingSortsByDayAndTime() async {
        let repository = MockScheduleRepository()
        repository.scheduleResult = .success([
            Fixtures.scheduleEntry(id: "s1", weekday: .friday, startTime: "20:30"),
            Fixtures.scheduleEntry(id: "s2", weekday: .monday, startTime: "18:30"),
            Fixtures.scheduleEntry(id: "s3", weekday: .friday, startTime: "18:30"),
        ])
        let viewModel = ScheduleViewModel(repository: repository)
        await viewModel.load()

        let groups = viewModel.entriesByDay

        #expect(groups.map(\.day) == [.monday, .friday])
        #expect(groups[1].entries.map(\.id) == ["s3", "s1"])
    }
}
