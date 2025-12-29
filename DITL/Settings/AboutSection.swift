import SwiftUI

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("About")
                .font(AppFonts.vt323(40))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // About card
            VStack(spacing: 12) {
                Text("App Version: v0.1")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black)

                Text("Made by Akshita <3")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black)

                Text("Icons by Flaticon")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(AppColors.black)
            }
            .padding(20)
            .background(AppColors.pinkCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }
}

#Preview {
    ZStack {
        AppColors.background
        AboutSection()
            .padding()
    }
}
