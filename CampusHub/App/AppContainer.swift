import Foundation
import SwiftData

/// Raiz de composição da aplicação: constrói as dependências concretas
/// (rede, persistência, repositórios) e injeta-as via inicializador.
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let scheduleRepository: any ScheduleRepositoryProtocol
    let timesheetRepository: any TimesheetRepositoryProtocol

    init(inMemory: Bool = false) throws {
        let schema = Schema([ScheduleEntryEntity.self, TimesheetEntryEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])

        let client = URLSessionHTTPClient(baseURL: AppConfig.apiBaseURL)
        let store = SwiftDataLocalStore(context: modelContainer.mainContext)
        scheduleRepository = ScheduleRepository(client: client, store: store)
        timesheetRepository = TimesheetRepository(client: client, store: store)
    }
}
