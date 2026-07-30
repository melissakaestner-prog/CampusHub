import SwiftUI

/// Ecrã da secretaria: alocar um professor a uma unidade curricular num
/// dia/horário/sala. O servidor rejeita alocações em conflito (HTTP 409).
struct AllocationView: View {
    @Bindable var viewModel: AllocationViewModel

    var body: some View {
        Form {
            Section("Unidade curricular") {
                Picker("UC", selection: $viewModel.selectedUnitID) {
                    Text("Selecionar…").tag(String?.none)
                    ForEach(viewModel.units) { unit in
                        Text("\(unit.name) — \(unit.course)").tag(Optional(unit.id))
                    }
                }
            }

            Section("Professor") {
                Picker("Professor", selection: $viewModel.selectedProfessorID) {
                    Text("Selecionar…").tag(String?.none)
                    ForEach(viewModel.professors) { professor in
                        Text(professor.name).tag(Optional(professor.id))
                    }
                }
            }

            Section("Dia e horário") {
                Picker("Dia da semana", selection: $viewModel.weekday) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Text(day.name).tag(day)
                    }
                }
                TextField("Início (HH:mm)", text: $viewModel.startTime)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Fim (HH:mm)", text: $viewModel.endTime)
                    .keyboardType(.numbersAndPunctuation)
            }

            Section("Sala e turma") {
                TextField("Sala", text: $viewModel.room)
                TextField("Turma (ex.: DS-2A)", text: $viewModel.classGroup)
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Criar alocação")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .navigationTitle("Alocação")
        .overlay {
            if viewModel.isLoadingOptions {
                ProgressView("A carregar opções…")
            }
        }
        .task {
            await viewModel.loadOptions()
        }
        .alert(
            "Não foi possível criar a alocação",
            isPresented: alertBinding(for: \.errorMessage)
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert(
            "Alocação criada",
            isPresented: alertBinding(for: \.successMessage)
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    private func alertBinding(
        for keyPath: ReferenceWritableKeyPath<AllocationViewModel, String?>
    ) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { isPresented in
                if !isPresented { viewModel[keyPath: keyPath] = nil }
            }
        )
    }
}
