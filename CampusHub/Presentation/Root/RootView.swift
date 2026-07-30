import SwiftUI

struct RootView: View {
    @AppStorage("userRole") private var roleRaw = UserRole.professor.rawValue
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    @State private var scheduleViewModel: ScheduleViewModel
    @State private var timesheetViewModel: TimesheetViewModel
    @State private var allocationViewModel: AllocationViewModel

    init(container: AppContainer) {
        _scheduleViewModel = State(initialValue: ScheduleViewModel(repository: container.scheduleRepository))
        _timesheetViewModel = State(initialValue: TimesheetViewModel(repository: container.timesheetRepository))
        _allocationViewModel = State(initialValue: AllocationViewModel(repository: container.scheduleRepository))
    }

    private var role: UserRole { UserRole(rawValue: roleRaw) ?? .professor }
    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }

    var body: some View {
        TabView {
            NavigationStack {
                ScheduleView(viewModel: scheduleViewModel)
            }
            .tabItem { Label("Horário", systemImage: "calendar") }

            if role == .professor {
                NavigationStack {
                    TimesheetView(viewModel: timesheetViewModel)
                }
                .tabItem { Label("Horas", systemImage: "clock") }
            }

            if role == .secretary {
                NavigationStack {
                    AllocationView(viewModel: allocationViewModel)
                }
                .tabItem { Label("Alocação", systemImage: "person.2.badge.gearshape") }
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Definições", systemImage: "gearshape") }
        }
        .preferredColorScheme(theme.colorScheme)
    }
}
