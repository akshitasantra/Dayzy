import SwiftUI

struct PeriodTrendsCard: View {
    let totalMinutes: Int
    let previousMinutes: Int?
    let scope: WrappedScope

    private let cardBackground = AppColors.card()

    var body: some View {
        VStack(spacing: 16) {
            Text("Trends vs. last \(scopeText())")
                .font(AppFonts.vt323(24))
                .foregroundColor(AppColors.primary())

            if let previous = previousMinutes {
                let diff = totalMinutes - previous
                let percent = previous > 0 ? Double(diff) / Double(previous) * 100 : 0

                HStack(spacing: 12) {
                    // Arrow indicator
                    Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(AppColors.text(on: cardBackground))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total: \(totalMinutes) min")
                            .font(AppFonts.rounded(18))
                            .foregroundColor(AppColors.text(on: cardBackground))
                        Text("Average per \(averageUnit()): \(averageMinutes()) min")
                            .font(AppFonts.rounded(16))
                            .foregroundColor(AppColors.text(on: cardBackground))
                        Text(String(format: "Change: %.0f%%", abs(percent)))
                            .font(AppFonts.rounded(16))
                            .foregroundColor(AppColors.text(on: cardBackground))
                    }
                }
            } else {
                Text("No data from previous \(scopeText())")
                    .font(AppFonts.rounded(16))
                    .foregroundColor(AppColors.text(on: cardBackground))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.card())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }

    private func scopeText() -> String {
        switch scope {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }

    private func averageUnit() -> String {
        switch scope {
        case .week: return "day"
        case .month: return "day"
        case .year: return "month"
        }
    }

    private func averageMinutes() -> Int {
        switch scope {
        case .week:
            return totalMinutes / 7
        case .month:
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
            return totalMinutes / daysInMonth
        case .year:
            return totalMinutes / 12
        }
    }
}
