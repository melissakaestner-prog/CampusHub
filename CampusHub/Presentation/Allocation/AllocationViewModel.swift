import Foundation
import Observation

@MainActor
@Observable
final class AllocationViewModel {
    private let repository: any ScheduleRepositoryProtocol

    private(set) var professors: [Professor] = []
    private(set) var units: [CurricularUnit] = []
    private(set) var isLoadingOptions = false
    private(set) var isSaving = false
    var errorMessage: String?
    var successMessage: String?

    // Campos do formulário.
    var selectedProfessorID: String?
    var selectedUnitID: String?
    var weekday: Weekday = .monday
    var startTime = "18:30"
    var endTime = "21:30"
    var room = ""
    var classGroup = ""

    init(repository: any ScheduleRepositoryProtocol) {
        self.repository = repository
    }

    var canSave: Bool {
        selectedProfessorID != nil
            && selectedUnitID != nil
            && !room.trimmingCharacters(in: .whitespaces).isEmpty
            && !classGroup.trimmingCharacters(in: .whitespaces).isEmpty
            && startTime < endTime
    }

    func loadOptions() async {
        guard professors.isEmpty || units.isEmpty else { return }
        isLoadingOptions = true
        defer { isLoadingOptions = false }
        do {
            professors = try await repository.professors()
            units = try await repository.units()
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard let professorID = selectedProfessorID, let unitID = selectedUnitID else { return }
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        successMessage = nil

        let request = NewAllocationRequest(
            unitId: unitID,
            professorId: professorID,
            weekday: weekday.rawValue,
            startTime: startTime,
            endTime: endTime,
            room: room.trimmingCharacters(in: .whitespaces),
            classGroup: classGroup.trimmingCharacters(in: .whitespaces)
        )
        do {
            let entry = try await repository.createAllocation(request)
            successMessage = "\(entry.unit.name) alocada a \(entry.professor.name), \(entry.weekday.shortName) \(entry.timeRange), sala \(entry.room)."
            room = ""
            classGroup = ""
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
