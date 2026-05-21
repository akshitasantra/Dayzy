import Foundation
import SwiftUI
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    private let gymMonthlySummaryID = "monthly.gym.summary"

    private init() {
        checkAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
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
            isAuthorized = false
            cancelMonthlyGymSummary()
            cancelDailyLoggingReminder()
        } else {
            requestAuthorization()
        }
    }

    func scheduleDailyLoggingReminder() {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Dayzy Reminder"
        content.body = "Don’t forget to log your day today!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily.logging.reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["daily.logging.reminder"]
            )

        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelDailyLoggingReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["daily.logging.reminder"]
            )
    }
    
    func scheduleMonthlyGymSummary() {
        guard notificationsEnabled else { return }

        let calendar = Calendar.current
        let now = Date()

        guard let currentMonth = calendar.dateInterval(of: .month, for: now),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: currentMonth.start),
              let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextMonthStart)
        else { return }

        let gymMinutes = gymMinutesForMonth(containing: now)
        let remaining = max(0, 600 - gymMinutes)

        let content = UNMutableNotificationContent()
        content.title = "Gym Monthly Goal"
        content.sound = .default

        if gymMinutes >= 600 {
            content.body = "You hit your 600 minute Gym goal this month! Nice work :)"
        } else {
            content.body = "You logged \(formatMinutes(gymMinutes)) at Gym this month — \(formatMinutes(remaining)) away from 600"
        }

        let triggerDate = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: gymMonthlySummaryID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [gymMonthlySummaryID])
        UNUserNotificationCenter.current().add(request)
    }

    func cancelMonthlyGymSummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [gymMonthlySummaryID])
    }

    private func gymMinutesForMonth(containing date: Date) -> Int {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return 0 }

        let activities = DatabaseManager.shared.fetchActivities(
            in: monthInterval.start,
            end: monthInterval.end
        )

        return activities
            .filter { $0.title == "Gym" }
            .reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    private func formatMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}
