import Testing
import Foundation
@testable import CampusHub

@MainActor
struct TimesheetViewModelTests {
    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test("Carregamento com sucesso passa a loaded")
    func loadSuccessSetsLoaded() async {
        let repository = MockTimesheetRepository()
        let entries = [Fixtures.timesheetEntry(id: "t1")]
        repository.entriesResult = .success(entries)
        let viewModel = TimesheetViewModel(repository: repository, professorID: "p1")

        await viewModel.load()

        #expect(viewModel.state == .loaded(entries))
    }

    @Test("Erro passa a error com mensagem amigável")
    func loadFailureSetsError() async {
        let repository = MockTimesheetRepository()
        repository.entriesResult = .failure(.server(statusCode: 500))
        let viewModel = TimesheetViewModel(repository: repository, professorID: "p1")

        await viewModel.load()

        #expect(viewModel.state == .error(AppError.server(statusCode: 500).userMessage))
    }

    @Test("Resumo mensal soma horas por mês e ordena do mais recente para o mais antigo")
    func monthlySummariesGroupAndSort() async {
        let repository = MockTimesheetRepository()
        repository.entriesResult = .success([
            Fixtures.timesheetEntry(id: "t1", date: date("2026-07-06T00:00:00Z"), hours: 3),
            Fixtures.timesheetEntry(id: "t2", date: date("2026-07-07T00:00:00Z"), hours: 2.5),
            Fixtures.timesheetEntry(id: "t3", date: date("2026-06-15T00:00:00Z"), hours: 4),
        ])
        let viewModel = TimesheetViewModel(repository: repository, professorID: "p1")
        await viewModel.load()

        let summaries = viewModel.monthlySummaries

        #expect(summaries.count == 2)
        #expect(summaries[0].id == "2026-07")
        #expect(summaries[0].totalHours == 5.5)
        #expect(summaries[1].id == "2026-06")
        #expect(summaries[1].totalHours == 4)
    }

    @Test("Registar horas com sucesso insere o registo no topo da lista")
    func addEntryPrependsOnSuccess() async {
        let repository = MockTimesheetRepository()
        repository.entriesResult = .success([Fixtures.timesheetEntry(id: "t1")])
        let newEntry = Fixtures.timesheetEntry(id: "novo")
        repository.addResult = .success(newEntry)
        let viewModel = TimesheetViewModel(repository: repository, professorID: "p1")
        await viewModel.load()

        let success = await viewModel.addEntry(date: newEntry.date, hours: 3, unitName: newEntry.unitName)

        #expect(success)
        guard case .loaded(let entries) = viewModel.state else {
            Issue.record("Estado esperado: loaded")
            return
        }
        #expect(entries.first?.id == "novo")
        #expect(repository.lastAddRequest?.professorId == "p1")
    }

    @Test("Falha ao registar horas define errorMessage e devolve false")
    func addEntryFailureSetsErrorMessage() async {
        let repository = MockTimesheetRepository()
        repository.entriesResult = .success([Fixtures.timesheetEntry(id: "t1")])
        repository.addResult = .failure(.network("timeout"))
        let viewModel = TimesheetViewModel(repository: repository, professorID: "p1")
        await viewModel.load()

        let success = await viewModel.addEntry(date: Date(timeIntervalSince1970: 0), hours: 3, unitName: "UC")

        #expect(!success)
        #expect(viewModel.errorMessage == AppError.network("timeout").userMessage)
    }
}
