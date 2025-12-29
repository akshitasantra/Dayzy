import SwiftUI

struct PreferencesCard: View {
    var body: some View {
        ZStack {
            // Card background + content
            VStack(spacing: 16) {
                PreferenceButton(title: "Theme", iconName: "cloudy") {}
                PreferenceButton(title: "Notifications", iconName: "notification") {}
                PreferenceButton(title: "Sound", iconName: "high-volume") {}
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.pinkCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)

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
}

#Preview {
    ZStack {
        AppColors.background
        PreferencesCard()
            .padding()
    }
}


// Single preference button with custom icons
struct PreferenceButton: View {
    let title: String
    let iconName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon container with extra padding to shift right
                Image(iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16) // shift right
                    .frame(width: 40, alignment: .leading) // keep consistent x-position

                Text(title)
                    .font(AppFonts.rounded(18))
                    .foregroundColor(.black)

                Spacer() // push text left, keep button width consistent
            }
            .padding(.vertical, 16)
            .frame(width: 200)
            .background(AppColors.lavenderQuick)
            .cornerRadius(AppLayout.cornerRadius)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}


