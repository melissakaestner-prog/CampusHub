import Foundation
import Observation

/// Total de horas letivas num mês, para o resumo enviado ao coordenador.
struct MonthlySummary: Identifiable, Equatable {
    /// Chave ordenável no formato "yyyy-MM".
    let id: String
    /// Título legível (ex.: "Julho 2026").
    let title: String
    let totalHours: Double
}

@MainActor
@Observable
final class TimesheetViewModel {
    private let repository: any TimesheetRepositoryProtocol
    private let professorID: String

    private(set) var state: ViewState<[TimesheetEntry]> = .idle
    private(set) var isSaving = false
    var errorMessage: String?

    init(
        repository: any TimesheetRepositoryProtocol,
        professorID: String = AppConfig.currentProfessorID
    ) {
        self.repository = repository
        self.professorID = professorID
    }

    var monthlySummaries: [MonthlySummary] {
        guard case .loaded(let entries) = state else { return [] }

        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "LLLL yyyy"
        titleFormatter.locale = Locale(identifier: "pt_PT")

        let grouped = Dictionary(grouping: entries) { keyFormatter.string(from: $0.date) }
        return grouped
            .map { key, monthEntries in
                MonthlySummary(
                    id: key,
                    title: titleFormatter.string(from: monthEntries[0].date).capitalized,
                    totalHours: monthEntries.reduce(0) { $0 + $1.hours }
                )
            }
            .sorted { $0.id > $1.id }
    }

    func load() async {
        state = .loading
        do {
            let entries = try await repository.loadEntries(professorID: professorID)
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch let error as AppError {
            state = .error(error.userMessage)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Regista horas. Devolve `true` em caso de sucesso (para fechar a folha).
    func addEntry(date: Date, hours: Double, unitName: String) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let request = NewTimesheetRequest(
            professorId: professorID,
            date: date,
            hours: hours,
            unitName: unitName
        )
        do {
            let entry = try await repository.addEntry(request)
            if case .loaded(var entries) = state {
                entries.insert(entry, at: 0)
                state = .loaded(entries)
            } else {
                state = .loaded([entry])
            }
            return true
        } catch let error as AppError {
            errorMessage = error.userMessage
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
