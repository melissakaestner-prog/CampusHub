import Testing
import Foundation
@testable import CampusHub

@MainActor
struct AllocationViewModelTests {
    private func makeViewModel(repository: MockScheduleRepository) -> AllocationViewModel {
        let viewModel = AllocationViewModel(repository: repository)
        viewModel.selectedProfessorID = "p1"
        viewModel.selectedUnitID = "u1"
        viewModel.room = "B2.04"
        viewModel.classGroup = "DS-2A"
        return viewModel
    }

    @Test("Formulário incompleto não permite guardar")
    func incompleteFormCannotSave() {
        let viewModel = AllocationViewModel(repository: MockScheduleRepository())

        #expect(!viewModel.canSave)

        viewModel.selectedProfessorID = "p1"
        viewModel.selectedUnitID = "u1"
        viewModel.room = "B2.04"
        viewModel.classGroup = "DS-2A"
        #expect(viewModel.canSave)
    }

    @Test("Hora de início posterior à de fim invalida o formulário")
    func invalidTimeRangeCannotSave() {
        let viewModel = makeViewModel(repository: MockScheduleRepository())

        viewModel.startTime = "21:30"
        viewModel.endTime = "18:30"

        #expect(!viewModel.canSave)
    }

    @Test("Guardar com sucesso define successMessage e envia o pedido correto")
    func saveSuccessSetsMessage() async {
        let repository = MockScheduleRepository()
        repository.allocationResult = .success(Fixtures.scheduleEntry(id: "novo"))
        let viewModel = makeViewModel(repository: repository)
        viewModel.weekday = .thursday

        await viewModel.save()

        #expect(viewModel.successMessage != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(repository.lastAllocationRequest?.weekday == Weekday.thursday.rawValue)
        #expect(repository.lastAllocationRequest?.unitId == "u1")
    }

    @Test("Conflito de horário apresenta a mensagem de conflito")
    func conflictSetsErrorMessage() async {
        let repository = MockScheduleRepository()
        repository.allocationResult = .failure(.scheduleConflict)
        let viewModel = makeViewModel(repository: repository)

        await viewModel.save()

        #expect(viewModel.errorMessage == AppError.scheduleConflict.userMessage)
        #expect(viewModel.successMessage == nil)
    }
}
