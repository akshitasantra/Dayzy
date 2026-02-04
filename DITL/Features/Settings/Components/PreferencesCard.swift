import SwiftUI

enum AppNotifications {
    static let enabledKey = "notificationsEnabled"
}

enum AppSound {
    static let enabledKey = "soundEnabled"
}

struct PreferencesCard: View {
    @State private var showingThemePicker = false
    @ObservedObject private var themeManager = ThemeManager.shared

    @AppStorage(AppNotifications.enabledKey) private var notificationsEnabled = false
    @AppStorage(AppSound.enabledKey) private var soundEnabled = true

    private var cardColor: Color { Color(hex: themeManager.theme.cardColorHex) }
    private var primaryColor: Color { Color(hex: themeManager.theme.primaryColorHex) }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                PreferenceButton(
                    title: "Theme",
                    iconName: "paintbrush",
                    backgroundColor: cardColor,
                    borderColor: primaryColor
                ) {
                    showingThemePicker.toggle()
                }

                PreferenceButton(
                    title: "Notifications",
                    iconName: notificationsEnabled ? "notification" : "mute-notification",
                    backgroundColor: cardColor,
                    borderColor: primaryColor
                ) {
                    toggleNotifications()
                }

                PreferenceButton(
                    title: "Sound",
                    iconName: soundEnabled ? "high-volume" : "mute",
                    backgroundColor: cardColor,
                    borderColor: primaryColor
                ) {
                    soundEnabled.toggle()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(cardColor)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(primaryColor, lineWidth: 1)
            )
            .shadow(color: primaryColor.opacity(0.1), radius: 12, x: 0, y: 4)

            // Decorative icons anchored to card corners
            .overlay(alignment: .topLeading) {
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
            .overlay(alignment: .bottomTrailing) {
                Image("love")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView(
                selectedCardColor: Binding(
                    get: { cardColor },
                    set: { themeManager.update(cardColor: $0) }
                ),
                selectedPrimaryColor: Binding(
                    get: { primaryColor },
                    set: { themeManager.update(primaryColor: $0) }
                ),
                useDarkBackground: Binding(
                    get: { themeManager.theme.useDarkBackground },
                    set: { themeManager.update(useDarkBackground: $0) }
                )
            )
        }
    }

    private func toggleNotifications() {
        if notificationsEnabled {
            NotificationManager.shared.cancelAll()
            notificationsEnabled = false
        } else {
            NotificationManager.shared.requestPermission { granted in
                if granted {
                    NotificationManager.shared.scheduleDailyReminder()
                    notificationsEnabled = true
                }
            }
        }
    }
}

// MARK: Preference Button
struct PreferenceButton: View {
    let title: String
    let iconName: String
    var backgroundColor: Color
    var borderColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16)
                    .frame(width: 40, alignment: .leading)

                Text(title)
                    .font(AppFonts.rounded(18))
                    .foregroundColor(AppColors.text(on: backgroundColor))

                Spacer()
            }
            .padding(.vertical, 16)
            .frame(width: 200)
            .background(backgroundColor)
            .cornerRadius(AppLayout.cornerRadius)
        }
        .withClickSound()
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: borderColor.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

// MARK: Button Click Sound
extension Button {
    func withClickSound() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                if UserDefaults.standard.bool(
                    forKey: AppSound.enabledKey
                ) {
                    SoundManager.shared.playClick()
                }
            }
        )
    }
}
