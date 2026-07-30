import Foundation

/// Uma aula alocada: unidade curricular + professor + dia/hora/sala/turma.
struct ScheduleEntry: Identifiable, Equatable, Sendable {
    let id: String
    let unit: CurricularUnit
    let professor: Professor
    let weekday: Weekday
    /// Formato "HH:mm" (24h). Strings neste formato ordenam corretamente.
    let startTime: String
    let endTime: String
    let room: String
    /// Turma (ex.: "DS-2A").
    let classGroup: String

    var timeRange: String { "\(startTime) – \(endTime)" }
}
