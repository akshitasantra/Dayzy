import Foundation
import SwiftUI

struct BiggestDayCard: View {
    let date: Date
    let minutes: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Biggest Day")
                .font(AppFonts.vt323(28))
                .foregroundColor(AppColors.primary())

            Text("\(formattedDate(date))")
                .font(AppFonts.rounded(16))
                .foregroundColor(AppColors.text(on: AppColors.card()))

            Text("\(minutes) min")
                .font(AppFonts.vt323(24))
                .foregroundColor(AppColors.lavenderQuick())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.card())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, EEEE"
        return formatter.string(from: date)
    }
}
