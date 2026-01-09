import SwiftUI

struct AboutSection: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("About")
                .font(AppFonts.vt323(40))
                .foregroundColor(AppColors.black(for: appTheme))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // About card
            VStack(spacing: 12) {
                Text("App Version: v0.1")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black(for: appTheme))

                Text("Made by Akshita <3")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black(for: appTheme))

                Text("Icons by Flaticon")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black(for: appTheme))
            }
            .padding(20)
            .background(AppColors.pinkCard(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
            .shadow(color: AppColors.black(for: appTheme).opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }
}
