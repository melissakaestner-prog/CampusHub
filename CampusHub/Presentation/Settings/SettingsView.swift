import SwiftUI

struct SettingsView: View {
    @AppStorage("userRole") private var roleRaw = UserRole.professor.rawValue
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    var body: some View {
        Form {
            Section("Perfil") {
                Picker("Perfil ativo", selection: $roleRaw) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.label).tag(role.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Aparência") {
                Picker("Tema", selection: $themeRaw) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
            }

            Section("Sobre") {
                LabeledContent("Aplicação", value: "CampusHub")
                LabeledContent("Versão", value: "1.0.0")
                LabeledContent("API", value: AppConfig.apiBaseURL.absoluteString)
            }

            Section {
                Text("Trabalho final da disciplina de Desenvolvimento iOS — Mestrado em Dispositivos Móveis e Multimédia.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Definições")
    }
}
