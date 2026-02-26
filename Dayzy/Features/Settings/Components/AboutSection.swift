import SwiftUI

struct AboutSection: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    private var cardColor: Color { Color(hex: themeManager.theme.cardColorHex) }
    private var textColor: Color { Color(hex: themeManager.theme.primaryColorHex) }

    var body: some View {
        VStack(spacing: 16) {
            Text("About")
                .font(AppFonts.vt323(40))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("App Version: v1.1")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(textColor)

                Text("Made by Akshita <3")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(textColor)

                Text("Icons by Flaticon")
                    .font(AppFonts.vt323(18))
                    .foregroundColor(textColor)
            }
            .padding(20)
            .background(cardColor)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(textColor, lineWidth: 1)
            )
            .shadow(color: textColor.opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }
}
