import Testing
import Foundation
@testable import CampusHub

@MainActor
struct ScheduleRepositoryTests {
    @Test("Sucesso remoto devolve dados e atualiza a cache local")
    func remoteSuccessUpdatesCache() async throws {
        let client = MockHTTPClient()
        client.getStubs["schedule"] = [Fixtures.scheduleEntryDTO(id: "s1"), Fixtures.scheduleEntryDTO(id: "s2")]
        let store = InMemoryLocalStore()
        let repository = ScheduleRepository(client: client, store: store)

        let entries = try await repository.loadSchedule()

        #expect(entries.count == 2)
        #expect(store.schedule == entries)
    }

    @Test("Falha de rede devolve os dados em cache")
    func networkFailureFallsBackToCache() async throws {
        let client = MockHTTPClient()
        client.error = .network("timeout")
        let store = InMemoryLocalStore()
        let cached = [Fixtures.scheduleEntry(id: "cached")]
        store.schedule = cached
        let repository = ScheduleRepository(client: client, store: store)

        let entries = try await repository.loadSchedule()

        #expect(entries == cached)
    }

    @Test("Falha de rede sem cache lança offlineWithoutCache")
    func networkFailureWithoutCacheThrows() async {
        let client = MockHTTPClient()
        client.error = .network("timeout")
        let store = InMemoryLocalStore()
        let repository = ScheduleRepository(client: client, store: store)

        await #expect(throws: AppError.offlineWithoutCache) {
            _ = try await repository.loadSchedule()
        }
    }

    @Test("Entradas com dia da semana inválido são descartadas")
    func invalidWeekdayIsDiscarded() async throws {
        let client = MockHTTPClient()
        client.getStubs["schedule"] = [Fixtures.scheduleEntryDTO(id: "s1", weekday: 1), Fixtures.scheduleEntryDTO(id: "s2", weekday: 99)]
        let store = InMemoryLocalStore()
        let repository = ScheduleRepository(client: client, store: store)

        let entries = try await repository.loadSchedule()

        #expect(entries.count == 1)
        #expect(entries.first?.id == "s1")
    }

    @Test("Criar alocação guarda a entrada na cache local")
    func createAllocationInsertsIntoCache() async throws {
        let client = MockHTTPClient()
        client.postStubs["schedule"] = Fixtures.scheduleEntryDTO(id: "novo")
        let store = InMemoryLocalStore()
        let repository = ScheduleRepository(client: client, store: store)

        let request = NewAllocationRequest(
            unitId: "u1", professorId: "p1", weekday: 1,
            startTime: "18:30", endTime: "21:30", room: "B2.04", classGroup: "DS-2A"
        )
        let entry = try await repository.createAllocation(request)

        #expect(entry.id == "novo")
        #expect(store.schedule.contains(entry))
    }

    @Test("Conflito de horário (HTTP 409) propaga scheduleConflict")
    func allocationConflictPropagates() async {
        let client = MockHTTPClient()
        client.error = .scheduleConflict
        let store = InMemoryLocalStore()
        let repository = ScheduleRepository(client: client, store: store)

        let request = NewAllocationRequest(
            unitId: "u1", professorId: "p1", weekday: 1,
            startTime: "18:30", endTime: "21:30", room: "B2.04", classGroup: "DS-2A"
        )
        await #expect(throws: AppError.scheduleConflict) {
            _ = try await repository.createAllocation(request)
        }
    }
}
