import SwiftUI

struct WrappedTotalTimeCard: View {
    @AppStorage("customThemeData") private var customThemeData: Data?

    private let cardBackground = AppColors.card()
    
    let totalMinutes: Int
    let previousMinutes: Int?       // total for previous period
    let scope: WrappedScope         // <-- pass the current scope

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("Total Time")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.text(on: cardBackground))

            // Total minutes
            Text(formatMinutes(totalMinutes))
                .font(AppFonts.vt323(36))
                .foregroundColor(AppColors.primary())

            // Comparison vs previous period
            if let previous = previousMinutes {
                HStack(spacing: 4) {
                    let diff = totalMinutes - previous
                    let percent = previous > 0 ? Double(diff) / Double(previous) * 100 : 0
                    let arrow = diff >= 0 ? "arrow.up" : "arrow.down"

                    Image(systemName: arrow)
                        .font(.caption2)
                        .foregroundColor(AppColors.text(on: cardBackground))

                    Text(String(format: "vs. %@ (last %@) %.0f%%", formatMinutes(previous), scopeName(), abs(percent)))
                        .font(AppFonts.rounded(14))
                        .foregroundColor(AppColors.text(on: cardBackground))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.card())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)

        // Decorative corner images
        .overlay(alignment: .topLeading) {
            Image("love")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            Image("love")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            Image("love-always-wins")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(12)
        }
        .overlay(alignment: .bottomLeading) {
            Image("love-always-wins")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(12)
        }
    }

    private func scopeName() -> String {
        switch scope {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
}
