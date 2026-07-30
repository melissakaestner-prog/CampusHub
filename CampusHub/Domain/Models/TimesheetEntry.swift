import Foundation

enum TimesheetStatus: String, Codable, Sendable {
    case draft
    case submitted

    var label: String {
        switch self {
        case .draft: "Rascunho"
        case .submitted: "Enviado"
        }
    }
}

/// Registo de horas letivas de um professor num determinado dia.
struct TimesheetEntry: Identifiable, Equatable, Sendable {
    let id: String
    let professorId: String
    let date: Date
    let hours: Double
    let unitName: String
    let status: TimesheetStatus
}
