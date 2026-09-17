import SwiftUI

@MainActor
struct RootView: View {
    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppStorageKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue
    @State private var selectedTab: AppTab = .attendance

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AttendanceView()
            }
            .tabItem {
                Label("Chấm công", systemImage: "calendar.badge.clock")
            }
            .tag(AppTab.attendance)

            NavigationStack {
                ReportView()
            }
            .tabItem {
                Label("Báo cáo", systemImage: "doc.text")
            }
            .tag(AppTab.report)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Cài đặt", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .tint(AppTheme.indigo)
        .toolbarBackground(AppTheme.elevatedBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(selectedAppearance.preferredColorScheme)
        .onChange(of: selectedTab) { _, _ in
            HapticFeedback.selection(isEnabled: hapticsEnabled)
        }
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }
}

private enum AppTab: Hashable {
    case attendance
    case report
    case settings
}

#Preview {
    RootView()
        .modelContainer(for: WorkEntry.self, inMemory: true)
}
