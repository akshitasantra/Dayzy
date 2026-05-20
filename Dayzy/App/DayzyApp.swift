import SwiftUI

@main
struct DayzyApp: App {

    init() {
        NotificationManager.shared.requestAuthorization()

        NotificationManager.shared.scheduleMonthlyGymSummary()

        NotificationManager.shared.scheduleDailyLoggingReminder()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
