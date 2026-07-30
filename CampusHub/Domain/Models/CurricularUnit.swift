import Foundation

struct CurricularUnit: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// Curso a que a unidade pertence (ex.: "CTeSP Desenvolvimento de Software").
    let course: String
}
