import Foundation

/// Perfil ativo na aplicação. Define os separadores visíveis.
enum UserRole: String, CaseIterable, Identifiable {
    case professor
    case student
    case secretary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .professor: "Professor"
        case .student: "Aluno"
        case .secretary: "Secretaria"
        }
    }
}
