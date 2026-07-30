import Foundation

/// Pedido de registo de horas letivas.
struct NewTimesheetRequest: Encodable, Equatable, Sendable {
    let professorId: String
    let date: Date
    let hours: Double
    let unitName: String
}

/// Abstração do acesso aos registos de horas letivas.
@MainActor
protocol TimesheetRepositoryProtocol {
    /// Carrega os registos do professor. Tenta a rede primeiro; em caso de
    /// falha, devolve os dados persistidos localmente.
    func loadEntries(professorID: String) async throws -> [TimesheetEntry]

    /// Regista horas no servidor e guarda o registo na cache local.
    func addEntry(_ request: NewTimesheetRequest) async throws -> TimesheetEntry
}
