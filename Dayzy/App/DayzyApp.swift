import SwiftUI

@main
struct DayzyApp: App {
    init() {
            NotificationManager.shared.requestAuthorization()
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
