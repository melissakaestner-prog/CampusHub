import Foundation

enum AppConfig {
    /// URL base da API. No simulador, 127.0.0.1 aponta para o Mac anfitrião,
    /// onde o backend (pasta `backend/`) deve estar a correr.
    static let apiBaseURL = URL(string: "http://127.0.0.1:3000/api")!

    /// Identificador do professor com sessão iniciada.
    /// Autenticação está fora do âmbito deste trabalho (ver README).
    static let currentProfessorID = "p1"
}
