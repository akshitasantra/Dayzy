import SwiftUI

enum AppNotifications {
    static let enabledKey = "notificationsEnabled"
}

enum AppSound {
    static let enabledKey = "soundEnabled"
}

struct PreferencesCard: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    @AppStorage(AppNotifications.enabledKey)
    private var notificationsEnabled = false
    @AppStorage(AppSound.enabledKey)
    private var soundEnabled = true

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                PreferenceButton(
                    title: "Theme",
                    iconName: themeIcon
                ) {
                    toggleTheme()
                }

                PreferenceButton(
                    title: "Notifications",
                    iconName: notificationsIcon
                ) {
                    toggleNotifications()
                }
                
                PreferenceButton(
                    title: "Sound",
                    iconName: soundEnabled ? "high-volume" : "mute"
                ) {
                    soundEnabled.toggle()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.pinkCard(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
            .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)

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
    }
    
    private var themeIcon: String {
        appTheme == .light ? "cloudy" : "dark-cloudy"
    }
    
    private var notificationsIcon: String {
        notificationsEnabled ? "notification" : "mute-notification"
    }
    
    private func toggleTheme() {
        appTheme = (appTheme == .light) ? .dark : .light
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


struct PreferenceButton: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let title: String
    let iconName: String
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
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.vertical, 16)
            .frame(width: 200)
            .background(AppColors.lavenderQuick(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
        }
        .withClickSound()
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
        )
        .shadow(color: AppColors.black(for: appTheme).opacity(0.1), radius: 12, x: 0, y: 4)
    }
}


