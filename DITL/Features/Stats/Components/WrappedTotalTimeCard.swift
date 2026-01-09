import SwiftUI

struct WrappedTotalTimeCard: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let totalMinutes: Int

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("Total Time Today")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.black(for: appTheme))

            // Total minutes
            Text("\(totalMinutes) minutes")
                .font(AppFonts.vt323(36))
                .foregroundColor(AppColors.pinkPrimary(for: appTheme))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.pinkCard(for: appTheme))
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
        )
        .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)
        
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
}
