import Foundation

// DTOs (Data Transfer Objects): espelham o JSON da API e são convertidos
// em modelos de domínio. Mantêm o domínio independente do formato remoto.

struct ProfessorDTO: Codable, Equatable {
    let id: String
    let name: String
    let email: String

    func toDomain() -> Professor {
        Professor(id: id, name: name, email: email)
    }
}

struct CurricularUnitDTO: Codable, Equatable {
    let id: String
    let name: String
    let course: String

    func toDomain() -> CurricularUnit {
        CurricularUnit(id: id, name: name, course: course)
    }
}

struct ScheduleEntryDTO: Codable, Equatable {
    let id: String
    let unit: CurricularUnitDTO
    let professor: ProfessorDTO
    let weekday: Int
    let startTime: String
    let endTime: String
    let room: String
    let classGroup: String

    /// Devolve `nil` se o dia da semana recebido for inválido — a entrada é
    /// descartada em vez de fazer a app falhar por dados corrompidos.
    func toDomain() -> ScheduleEntry? {
        guard let day = Weekday(rawValue: weekday) else { return nil }
        return ScheduleEntry(
            id: id,
            unit: unit.toDomain(),
            professor: professor.toDomain(),
            weekday: day,
            startTime: startTime,
            endTime: endTime,
            room: room,
            classGroup: classGroup
        )
    }
}

struct TimesheetEntryDTO: Codable, Equatable {
    let id: String
    let professorId: String
    let date: Date
    let hours: Double
    let unitName: String
    let status: String

    func toDomain() -> TimesheetEntry {
        TimesheetEntry(
            id: id,
            professorId: professorId,
            date: date,
            hours: hours,
            unitName: unitName,
            status: TimesheetStatus(rawValue: status) ?? .submitted
        )
    }
}
