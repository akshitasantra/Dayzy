import Foundation
import SwiftUI
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    private init() {
        checkAuthorization()
    }
    
    /// Ask permission immediately on first launch
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                self.notificationsEnabled = granted
            }
        }
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func toggleNotifications() {
        if notificationsEnabled {
            notificationsEnabled = false
            isAuthorized = false // immediately reflect in UI
        } else {
            requestAuthorization()
        }
    }

    func scheduleNotification(title: String, body: String, in seconds: TimeInterval) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
