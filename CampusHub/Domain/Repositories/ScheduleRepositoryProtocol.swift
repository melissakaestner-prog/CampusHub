import Foundation

/// Pedido de criação de uma alocação (usado pela secretaria).
struct NewAllocationRequest: Encodable, Equatable, Sendable {
    let unitId: String
    let professorId: String
    let weekday: Int
    let startTime: String
    let endTime: String
    let room: String
    let classGroup: String
}

/// Abstração do acesso ao horário e às alocações.
/// A implementação concreta combina rede + cache local (offline-first).
@MainActor
protocol ScheduleRepositoryProtocol {
    /// Carrega o horário completo. Tenta a rede primeiro; em caso de falha,
    /// devolve os dados persistidos localmente.
    func loadSchedule() async throws -> [ScheduleEntry]

    /// Lista de professores disponíveis para alocação (apenas remoto).
    func professors() async throws -> [Professor]

    /// Lista de unidades curriculares disponíveis para alocação (apenas remoto).
    func units() async throws -> [CurricularUnit]

    /// Cria uma nova alocação no servidor e guarda-a na cache local.
    func createAllocation(_ request: NewAllocationRequest) async throws -> ScheduleEntry
}
