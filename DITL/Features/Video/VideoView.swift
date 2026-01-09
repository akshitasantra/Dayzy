import SwiftUI

struct VideoView: View {
    // MARK: App Theme
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    // MARK: Callbacks
    let onSettingsTapped: () -> Void

    // MARK: Body
    var body: some View {
        ZStack {
            AppColors.background(for: appTheme)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Spacer for top padding
                HStack {
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // MARK: Header
                Text("Video Diary")
                    .font(AppFonts.vt323(42))
                    .foregroundColor(AppColors.pinkPrimary(for: appTheme))

                Text("Coming soon")
                    .font(AppFonts.rounded(18))
                    .foregroundColor(AppColors.black(for: appTheme))

                // MARK: Placeholder Icon
                Image(systemName: "video.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(AppColors.lavenderQuick(for: appTheme))
            }
            .multilineTextAlignment(.center)
        }
    }
}
