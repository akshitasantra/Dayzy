import Foundation

struct Activity: Identifiable {
    var id: Int
    var title: String
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int?
}
