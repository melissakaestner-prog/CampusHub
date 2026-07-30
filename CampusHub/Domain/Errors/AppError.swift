import Foundation

/// Erros tipados da aplicação. Todas as camadas propagam falhas através
/// deste enum, para que a UI apresente mensagens claras ao utilizador.
enum AppError: Error, Equatable {
    case invalidURL
    case network(String)
    case server(statusCode: Int)
    case decoding
    case scheduleConflict
    case persistence(String)
    case offlineWithoutCache

    var userMessage: String {
        switch self {
        case .invalidURL:
            "Endereço do serviço inválido."
        case .network:
            "Sem ligação ao servidor. Verifique a sua ligação à internet."
        case .server(let statusCode):
            "O servidor devolveu um erro (código \(statusCode)). Tente novamente."
        case .decoding:
            "A resposta do servidor tem um formato inesperado."
        case .scheduleConflict:
            "Conflito de horário: o professor ou a sala já estão ocupados nesse período."
        case .persistence(let detail):
            "Erro ao guardar dados localmente: \(detail)"
        case .offlineWithoutCache:
            "Sem ligação e sem dados guardados. Ligue-se à internet para carregar os dados pela primeira vez."
        }
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? { userMessage }
}
