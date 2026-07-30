import Testing
import Foundation
@testable import CampusHub

@MainActor
struct TimesheetRepositoryTests {
    @Test("Sucesso remoto devolve registos e atualiza a cache")
    func remoteSuccessUpdatesCache() async throws {
        let client = MockHTTPClient()
        client.getStubs["timesheets"] = [Fixtures.timesheetEntryDTO(id: "t1")]
        let store = InMemoryLocalStore()
        let repository = TimesheetRepository(client: client, store: store)

        let entries = try await repository.loadEntries(professorID: "p1")

        #expect(entries.count == 1)
        #expect(store.timesheet == entries)
    }

    @Test("Falha de rede devolve apenas os registos em cache do professor")
    func networkFailureFallsBackToCacheFilteredByProfessor() async throws {
        let client = MockHTTPClient()
        client.error = .network("timeout")
        let store = InMemoryLocalStore()
        store.timesheet = [
            Fixtures.timesheetEntry(id: "t1", professorId: "p1"),
            Fixtures.timesheetEntry(id: "t2", professorId: "p2"),
        ]
        let repository = TimesheetRepository(client: client, store: store)

        let entries = try await repository.loadEntries(professorID: "p1")

        #expect(entries.count == 1)
        #expect(entries.first?.id == "t1")
    }

    @Test("Falha de rede sem cache lança offlineWithoutCache")
    func networkFailureWithoutCacheThrows() async {
        let client = MockHTTPClient()
        client.error = .network("timeout")
        let store = InMemoryLocalStore()
        let repository = TimesheetRepository(client: client, store: store)

        await #expect(throws: AppError.offlineWithoutCache) {
            _ = try await repository.loadEntries(professorID: "p1")
        }
    }

    @Test("Registar horas guarda o registo na cache local")
    func addEntryInsertsIntoCache() async throws {
        let client = MockHTTPClient()
        client.postStubs["timesheets"] = Fixtures.timesheetEntryDTO(id: "novo")
        let store = InMemoryLocalStore()
        let repository = TimesheetRepository(client: client, store: store)

        let request = NewTimesheetRequest(
            professorId: "p1", date: Date(timeIntervalSince1970: 1_780_000_000),
            hours: 3, unitName: "Gestão de Projetos"
        )
        let entry = try await repository.addEntry(request)

        #expect(entry.id == "novo")
        #expect(store.timesheet.contains(entry))
    }
}
