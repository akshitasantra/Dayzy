import SwiftUI

struct WrappedTotalTimeCard: View {
    let totalMinutes: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Total Time Today")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.black)

            Text("\(totalMinutes) minutes")
                .font(AppFonts.vt323(36))
                .foregroundColor(AppColors.pinkPrimary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.pinkCard)
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)

        // Decorative icons (same as ActivityCard)
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
}
