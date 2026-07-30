import Foundation

/// Estratégia offline-first: tenta sempre a rede; em caso de sucesso
/// atualiza a cache local; em caso de falha devolve os dados em cache.
@MainActor
final class ScheduleRepository: ScheduleRepositoryProtocol {
    private let client: HTTPClientProtocol
    private let store: LocalStoreProtocol

    init(client: HTTPClientProtocol, store: LocalStoreProtocol) {
        self.client = client
        self.store = store
    }

    func loadSchedule() async throws -> [ScheduleEntry] {
        do {
            let dtos: [ScheduleEntryDTO] = try await client.get(.schedule)
            let entries = dtos.compactMap { $0.toDomain() }
            try? store.replaceSchedule(with: entries)
            return entries
        } catch let error as AppError {
            let cached = (try? store.fetchSchedule()) ?? []
            if !cached.isEmpty { return cached }
            if case .network = error { throw AppError.offlineWithoutCache }
            throw error
        }
    }

    func professors() async throws -> [Professor] {
        let dtos: [ProfessorDTO] = try await client.get(.professors)
        return dtos.map { $0.toDomain() }
    }

    func units() async throws -> [CurricularUnit] {
        let dtos: [CurricularUnitDTO] = try await client.get(.units)
        return dtos.map { $0.toDomain() }
    }

    func createAllocation(_ request: NewAllocationRequest) async throws -> ScheduleEntry {
        let dto: ScheduleEntryDTO = try await client.post(.newAllocation, body: request)
        guard let entry = dto.toDomain() else { throw AppError.decoding }
        try? store.insertScheduleEntry(entry)
        return entry
    }
}
