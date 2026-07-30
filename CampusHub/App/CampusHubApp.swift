import SwiftUI
import SwiftData

@main
struct CampusHubApp: App {
    private let container: AppContainer

    init() {
        do {
            container = try AppContainer()
        } catch {
            fatalError("Falha ao inicializar a aplicação: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .modelContainer(container.modelContainer)
    }
}
