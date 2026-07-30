import Foundation

@MainActor
final class TimesheetRepository: TimesheetRepositoryProtocol {
    private let client: HTTPClientProtocol
    private let store: LocalStoreProtocol

    init(client: HTTPClientProtocol, store: LocalStoreProtocol) {
        self.client = client
        self.store = store
    }

    func loadEntries(professorID: String) async throws -> [TimesheetEntry] {
        do {
            let dtos: [TimesheetEntryDTO] = try await client.get(.timesheets(professorID: professorID))
            let entries = dtos.map { $0.toDomain() }
            try? store.replaceTimesheet(professorID: professorID, with: entries)
            return entries
        } catch let error as AppError {
            let cached = (try? store.fetchTimesheet(professorID: professorID)) ?? []
            if !cached.isEmpty { return cached }
            if case .network = error { throw AppError.offlineWithoutCache }
            throw error
        }
    }

    func addEntry(_ request: NewTimesheetRequest) async throws -> TimesheetEntry {
        let dto: TimesheetEntryDTO = try await client.post(.newTimesheet, body: request)
        let entry = dto.toDomain()
        try? store.insertTimesheetEntry(entry)
        return entry
    }
}
