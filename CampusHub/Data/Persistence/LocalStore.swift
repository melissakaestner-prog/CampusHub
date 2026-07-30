import Foundation
import SwiftData

/// Abstração da persistência local. Permite substituir o SwiftData por um
/// mock em memória nos testes dos repositórios.
@MainActor
protocol LocalStoreProtocol {
    func fetchSchedule() throws -> [ScheduleEntry]
    func replaceSchedule(with entries: [ScheduleEntry]) throws
    func insertScheduleEntry(_ entry: ScheduleEntry) throws

    func fetchTimesheet(professorID: String) throws -> [TimesheetEntry]
    func replaceTimesheet(professorID: String, with entries: [TimesheetEntry]) throws
    func insertTimesheetEntry(_ entry: TimesheetEntry) throws
}

@MainActor
final class SwiftDataLocalStore: LocalStoreProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Horário

    func fetchSchedule() throws -> [ScheduleEntry] {
        let descriptor = FetchDescriptor<ScheduleEntryEntity>(
            sortBy: [SortDescriptor(\.weekday), SortDescriptor(\.startTime)]
        )
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func replaceSchedule(with entries: [ScheduleEntry]) throws {
        // Apaga registo a registo em vez de delete(model:): o batch delete
        // não é suportado em stores em memória (usados nos testes) e o
        // volume de dados aqui é sempre pequeno.
        let existing = try context.fetch(FetchDescriptor<ScheduleEntryEntity>())
        for entity in existing {
            context.delete(entity)
        }
        for entry in entries {
            context.insert(ScheduleEntryEntity(from: entry))
        }
        try context.save()
    }

    func insertScheduleEntry(_ entry: ScheduleEntry) throws {
        context.insert(ScheduleEntryEntity(from: entry))
        try context.save()
    }

    // MARK: - Registo de horas

    func fetchTimesheet(professorID: String) throws -> [TimesheetEntry] {
        let predicate = #Predicate<TimesheetEntryEntity> { $0.professorID == professorID }
        let descriptor = FetchDescriptor<TimesheetEntryEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func replaceTimesheet(professorID: String, with entries: [TimesheetEntry]) throws {
        let predicate = #Predicate<TimesheetEntryEntity> { $0.professorID == professorID }
        let existing = try context.fetch(FetchDescriptor<TimesheetEntryEntity>(predicate: predicate))
        for entity in existing {
            context.delete(entity)
        }
        for entry in entries {
            context.insert(TimesheetEntryEntity(from: entry))
        }
        try context.save()
    }

    func insertTimesheetEntry(_ entry: TimesheetEntry) throws {
        context.insert(TimesheetEntryEntity(from: entry))
        try context.save()
    }
}
