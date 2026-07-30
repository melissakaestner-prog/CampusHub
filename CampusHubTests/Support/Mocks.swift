import Foundation
@testable import CampusHub

// MARK: - Mock do cliente HTTP

final class MockHTTPClient: HTTPClientProtocol {
    /// Respostas simuladas para GET, indexadas pelo path do endpoint.
    var getStubs: [String: Any] = [:]
    /// Respostas simuladas para POST, indexadas pelo path do endpoint.
    var postStubs: [String: Any] = [:]
    /// Quando definido, todos os pedidos falham com este erro.
    var error: AppError?
    private(set) var getCallCount = 0
    private(set) var postCallCount = 0

    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        getCallCount += 1
        if let error { throw error }
        guard let value = getStubs[endpoint.path] as? T else {
            throw AppError.decoding
        }
        return value
    }

    func post<T: Decodable>(_ endpoint: Endpoint, body: some Encodable) async throws -> T {
        postCallCount += 1
        if let error { throw error }
        guard let value = postStubs[endpoint.path] as? T else {
            throw AppError.decoding
        }
        return value
    }
}

// MARK: - Mock da persistência local

@MainActor
final class InMemoryLocalStore: LocalStoreProtocol {
    var schedule: [ScheduleEntry] = []
    var timesheet: [TimesheetEntry] = []
    var shouldThrow = false

    private func checkError() throws {
        if shouldThrow { throw AppError.persistence("erro simulado") }
    }

    func fetchSchedule() throws -> [ScheduleEntry] {
        try checkError()
        return schedule
    }

    func replaceSchedule(with entries: [ScheduleEntry]) throws {
        try checkError()
        schedule = entries
    }

    func insertScheduleEntry(_ entry: ScheduleEntry) throws {
        try checkError()
        schedule.append(entry)
    }

    func fetchTimesheet(professorID: String) throws -> [TimesheetEntry] {
        try checkError()
        return timesheet.filter { $0.professorId == professorID }
    }

    func replaceTimesheet(professorID: String, with entries: [TimesheetEntry]) throws {
        try checkError()
        timesheet.removeAll { $0.professorId == professorID }
        timesheet.append(contentsOf: entries)
    }

    func insertTimesheetEntry(_ entry: TimesheetEntry) throws {
        try checkError()
        timesheet.append(entry)
    }
}

// MARK: - Mocks dos repositórios (para testes dos ViewModels)

@MainActor
final class MockScheduleRepository: ScheduleRepositoryProtocol {
    var scheduleResult: Result<[ScheduleEntry], AppError> = .success([])
    var professorsResult: Result<[Professor], AppError> = .success([])
    var unitsResult: Result<[CurricularUnit], AppError> = .success([])
    var allocationResult: Result<ScheduleEntry, AppError> = .failure(.decoding)
    private(set) var loadScheduleCallCount = 0
    private(set) var lastAllocationRequest: NewAllocationRequest?

    func loadSchedule() async throws -> [ScheduleEntry] {
        loadScheduleCallCount += 1
        return try scheduleResult.get()
    }

    func professors() async throws -> [Professor] {
        try professorsResult.get()
    }

    func units() async throws -> [CurricularUnit] {
        try unitsResult.get()
    }

    func createAllocation(_ request: NewAllocationRequest) async throws -> ScheduleEntry {
        lastAllocationRequest = request
        return try allocationResult.get()
    }
}

@MainActor
final class MockTimesheetRepository: TimesheetRepositoryProtocol {
    var entriesResult: Result<[TimesheetEntry], AppError> = .success([])
    var addResult: Result<TimesheetEntry, AppError> = .failure(.decoding)
    private(set) var lastAddRequest: NewTimesheetRequest?

    func loadEntries(professorID: String) async throws -> [TimesheetEntry] {
        try entriesResult.get()
    }

    func addEntry(_ request: NewTimesheetRequest) async throws -> TimesheetEntry {
        lastAddRequest = request
        return try addResult.get()
    }
}

// MARK: - Fixtures

enum Fixtures {
    static let professor = Professor(id: "p1", name: "Melissa Kaestner", email: "melissa@campus.pt")
    static let unit = CurricularUnit(id: "u1", name: "Gestão de Projetos", course: "CTeSP DS")

    static func scheduleEntry(
        id: String = "s1",
        weekday: Weekday = .monday,
        startTime: String = "18:30",
        unitName: String = "Gestão de Projetos",
        classGroup: String = "DS-2A"
    ) -> ScheduleEntry {
        ScheduleEntry(
            id: id,
            unit: CurricularUnit(id: "u-\(id)", name: unitName, course: "CTeSP DS"),
            professor: professor,
            weekday: weekday,
            startTime: startTime,
            endTime: "21:30",
            room: "B2.04",
            classGroup: classGroup
        )
    }

    static func scheduleEntryDTO(id: String = "s1", weekday: Int = 1) -> ScheduleEntryDTO {
        ScheduleEntryDTO(
            id: id,
            unit: CurricularUnitDTO(id: "u-\(id)", name: "Gestão de Projetos", course: "CTeSP DS"),
            professor: ProfessorDTO(id: "p1", name: "Melissa Kaestner", email: "melissa@campus.pt"),
            weekday: weekday,
            startTime: "18:30",
            endTime: "21:30",
            room: "B2.04",
            classGroup: "DS-2A"
        )
    }

    static func timesheetEntry(
        id: String = "t1",
        professorId: String = "p1",
        date: Date = Date(timeIntervalSince1970: 1_780_000_000),
        hours: Double = 3
    ) -> TimesheetEntry {
        TimesheetEntry(
            id: id,
            professorId: professorId,
            date: date,
            hours: hours,
            unitName: "Gestão de Projetos",
            status: .submitted
        )
    }

    static func timesheetEntryDTO(id: String = "t1") -> TimesheetEntryDTO {
        TimesheetEntryDTO(
            id: id,
            professorId: "p1",
            date: Date(timeIntervalSince1970: 1_780_000_000),
            hours: 3,
            unitName: "Gestão de Projetos",
            status: "submitted"
        )
    }
}
