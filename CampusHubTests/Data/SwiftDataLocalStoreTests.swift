import Testing
import Foundation
import SwiftData
@testable import CampusHub

/// Testes de integração da camada de persistência real (SwiftData),
/// usando um contentor apenas em memória.
@MainActor
struct SwiftDataLocalStoreTests {
    private func makeStore() throws -> SwiftDataLocalStore {
        let schema = Schema([ScheduleEntryEntity.self, TimesheetEntryEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return SwiftDataLocalStore(context: container.mainContext)
    }

    @Test("Guardar e ler o horário preserva os dados (roundtrip)")
    func scheduleRoundtrip() throws {
        let store = try makeStore()
        let entries = [
            Fixtures.scheduleEntry(id: "s1", weekday: .monday),
            Fixtures.scheduleEntry(id: "s2", weekday: .friday),
        ]

        try store.replaceSchedule(with: entries)
        let fetched = try store.fetchSchedule()

        #expect(fetched.count == 2)
        #expect(Set(fetched.map(\.id)) == ["s1", "s2"])
    }

    @Test("replaceSchedule substitui o conjunto anterior")
    func replaceScheduleOverwrites() throws {
        let store = try makeStore()
        try store.replaceSchedule(with: [Fixtures.scheduleEntry(id: "antigo")])

        try store.replaceSchedule(with: [Fixtures.scheduleEntry(id: "novo")])
        let fetched = try store.fetchSchedule()

        #expect(fetched.map(\.id) == ["novo"])
    }

    @Test("fetchTimesheet devolve apenas os registos do professor pedido")
    func timesheetFiltersByProfessor() throws {
        let store = try makeStore()
        try store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t1", professorId: "p1"))
        try store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t2", professorId: "p2"))

        let fetched = try store.fetchTimesheet(professorID: "p1")

        #expect(fetched.map(\.id) == ["t1"])
    }

    @Test("replaceTimesheet não afeta registos de outros professores")
    func replaceTimesheetIsScopedToProfessor() throws {
        let store = try makeStore()
        try store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t1", professorId: "p1"))
        try store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t2", professorId: "p2"))

        try store.replaceTimesheet(professorID: "p1", with: [Fixtures.timesheetEntry(id: "t3", professorId: "p1")])

        #expect(try store.fetchTimesheet(professorID: "p1").map(\.id) == ["t3"])
        #expect(try store.fetchTimesheet(professorID: "p2").map(\.id) == ["t2"])
    }
}
