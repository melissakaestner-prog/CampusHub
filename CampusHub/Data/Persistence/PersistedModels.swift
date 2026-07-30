import Foundation
import SwiftData

// Entidades SwiftData. Optou-se por um snapshot desnormalizado (sem
// relações) porque os dados locais são uma cache de leitura do servidor:
// a sincronização substitui o conjunto completo, o que torna relações
// entre entidades desnecessárias e simplifica a consistência offline.

@Model
final class ScheduleEntryEntity {
    @Attribute(.unique) var id: String
    var unitID: String
    var unitName: String
    var course: String
    var professorID: String
    var professorName: String
    var professorEmail: String
    var weekday: Int
    var startTime: String
    var endTime: String
    var room: String
    var classGroup: String

    init(from entry: ScheduleEntry) {
        id = entry.id
        unitID = entry.unit.id
        unitName = entry.unit.name
        course = entry.unit.course
        professorID = entry.professor.id
        professorName = entry.professor.name
        professorEmail = entry.professor.email
        weekday = entry.weekday.rawValue
        startTime = entry.startTime
        endTime = entry.endTime
        room = entry.room
        classGroup = entry.classGroup
    }

    func toDomain() -> ScheduleEntry? {
        guard let day = Weekday(rawValue: weekday) else { return nil }
        return ScheduleEntry(
            id: id,
            unit: CurricularUnit(id: unitID, name: unitName, course: course),
            professor: Professor(id: professorID, name: professorName, email: professorEmail),
            weekday: day,
            startTime: startTime,
            endTime: endTime,
            room: room,
            classGroup: classGroup
        )
    }
}

@Model
final class TimesheetEntryEntity {
    @Attribute(.unique) var id: String
    var professorID: String
    var date: Date
    var hours: Double
    var unitName: String
    var status: String

    init(from entry: TimesheetEntry) {
        id = entry.id
        professorID = entry.professorId
        date = entry.date
        hours = entry.hours
        unitName = entry.unitName
        status = entry.status.rawValue
    }

    func toDomain() -> TimesheetEntry {
        TimesheetEntry(
            id: id,
            professorId: professorID,
            date: date,
            hours: hours,
            unitName: unitName,
            status: TimesheetStatus(rawValue: status) ?? .submitted
        )
    }
}
