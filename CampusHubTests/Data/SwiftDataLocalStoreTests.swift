import Testing
import Foundation
import SwiftData
@testable import CampusHub

/// Testes de integração da camada de persistência real (SwiftData),
/// com um store SQLite em ficheiro temporário por teste.
///
/// Importante: o ModelContext não retém o seu ModelContainer. O harness
/// mantém uma referência forte ao contentor durante o teste — sem ela, o
/// contentor era desalocado no fim do helper e a primeira operação sobre
/// o contexto crashava com SIGTRAP ("no active container").
@Suite(.serialized)
@MainActor
struct SwiftDataLocalStoreTests {
    private struct StoreHarness {
        let container: ModelContainer
        let store: SwiftDataLocalStore
    }

    private func makeStore() throws -> StoreHarness {
        let schema = Schema([ScheduleEntryEntity.self, TimesheetEntryEntity.self])
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("campushub-tests-\(UUID().uuidString).store")
        let configuration = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return StoreHarness(
            container: container,
            store: SwiftDataLocalStore(context: container.mainContext)
        )
    }

    @Test("Guardar e ler o horário preserva os dados (roundtrip)")
    func scheduleRoundtrip() throws {
        let harness = try makeStore()
        let entries = [
            Fixtures.scheduleEntry(id: "s1", weekday: .monday),
            Fixtures.scheduleEntry(id: "s2", weekday: .friday),
        ]

        try harness.store.replaceSchedule(with: entries)
        let fetched = try harness.store.fetchSchedule()

        #expect(fetched.count == 2)
        #expect(Set(fetched.map(\.id)) == ["s1", "s2"])
    }

    @Test("replaceSchedule substitui o conjunto anterior")
    func replaceScheduleOverwrites() throws {
        let harness = try makeStore()
        try harness.store.replaceSchedule(with: [Fixtures.scheduleEntry(id: "antigo")])

        try harness.store.replaceSchedule(with: [Fixtures.scheduleEntry(id: "novo")])
        let fetched = try harness.store.fetchSchedule()

        #expect(fetched.map(\.id) == ["novo"])
    }

    @Test("fetchTimesheet devolve apenas os registos do professor pedido")
    func timesheetFiltersByProfessor() throws {
        let harness = try makeStore()
        try harness.store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t1", professorId: "p1"))
        try harness.store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t2", professorId: "p2"))

        let fetched = try harness.store.fetchTimesheet(professorID: "p1")

        #expect(fetched.map(\.id) == ["t1"])
    }

    @Test("replaceTimesheet não afeta registos de outros professores")
    func replaceTimesheetIsScopedToProfessor() throws {
        let harness = try makeStore()
        try harness.store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t1", professorId: "p1"))
        try harness.store.insertTimesheetEntry(Fixtures.timesheetEntry(id: "t2", professorId: "p2"))

        try harness.store.replaceTimesheet(professorID: "p1", with: [Fixtures.timesheetEntry(id: "t3", professorId: "p1")])

        #expect(try harness.store.fetchTimesheet(professorID: "p1").map(\.id) == ["t3"])
        #expect(try harness.store.fetchTimesheet(professorID: "p2").map(\.id) == ["t2"])
    }
}
