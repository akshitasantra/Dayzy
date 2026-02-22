enum WrappedScope: String, CaseIterable, Identifiable {
    case week = "Last Week"
    case month = "Last Month"
    case year = "Last Year"

    var id: String { rawValue }

    // Clean scope name for legends
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}
