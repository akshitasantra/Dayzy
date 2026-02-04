import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var onBack: () -> Void

    private var backgroundColor: Color {
        themeManager.theme.useDarkBackground ? Color(hex: "#2A2A28") : Color.white
    }

    private var primaryColor: Color {
        Color(hex: themeManager.theme.primaryColorHex)
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(backgroundColor == .black ? .white : .black)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                VStack(spacing: 32) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("Settings")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(primaryColor)

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    PreferencesCard()
                    AboutSection()
                }
                .padding(.top, 43)
                .padding(.horizontal, AppLayout.screenPadding)

                Spacer()
            }
        }
    }
}
