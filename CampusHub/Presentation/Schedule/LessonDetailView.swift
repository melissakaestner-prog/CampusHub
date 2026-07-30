import SwiftUI

struct LessonDetailView: View {
    let entry: ScheduleEntry

    var body: some View {
        List {
            Section("Unidade curricular") {
                LabeledContent("Nome", value: entry.unit.name)
                LabeledContent("Curso", value: entry.unit.course)
            }

            Section("Professor") {
                LabeledContent("Nome", value: entry.professor.name)
                LabeledContent("Email", value: entry.professor.email)
            }

            Section("Aula") {
                LabeledContent("Dia", value: entry.weekday.name)
                LabeledContent("Horário", value: entry.timeRange)
                LabeledContent("Sala", value: entry.room)
                LabeledContent("Turma", value: entry.classGroup)
            }
        }
        .navigationTitle(entry.unit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
