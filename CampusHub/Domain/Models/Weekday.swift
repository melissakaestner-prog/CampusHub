import Foundation

enum Weekday: Int, CaseIterable, Codable, Sendable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    var name: String {
        switch self {
        case .monday: "Segunda-feira"
        case .tuesday: "Terça-feira"
        case .wednesday: "Quarta-feira"
        case .thursday: "Quinta-feira"
        case .friday: "Sexta-feira"
        case .saturday: "Sábado"
        case .sunday: "Domingo"
        }
    }

    var shortName: String {
        switch self {
        case .monday: "Seg"
        case .tuesday: "Ter"
        case .wednesday: "Qua"
        case .thursday: "Qui"
        case .friday: "Sex"
        case .saturday: "Sáb"
        case .sunday: "Dom"
        }
    }
}
