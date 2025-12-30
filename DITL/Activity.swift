import SwiftUI

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let startTime: Date
    let endTime: Date?
}
