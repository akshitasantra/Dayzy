import Foundation

struct Activity: Identifiable {
    let id: Int            // SQLite row id
    let title: String
    let startTime: Date
    let endTime: Date?
    let durationMinutes: Int?
}
