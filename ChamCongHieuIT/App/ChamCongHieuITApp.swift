import SwiftData
import SwiftUI

@main
struct ChamCongHieuITApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, AppLocale.vietnamese)
        }
        .modelContainer(for: WorkEntry.self)
    }
}
