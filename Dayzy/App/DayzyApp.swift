import SwiftUI

import SwiftUI

@main
struct DayzyApp: App {

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        NotificationManager.shared.checkAuthorization()
                        NotificationManager.shared.scheduleMonthlyGymSummary()
                    }
                }
        }
    }
}
