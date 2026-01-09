import SwiftUI

struct WrappedActivityRow: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let activity: Activity
    let minutes: Int

    var body: some View {
        HStack {
            // Activity title
            Text(activity.title)
                .font(AppFonts.rounded(18))
                .foregroundColor(.black)

            Spacer()

            // Duration
            Text("\(minutes) min")
                .font(AppFonts.vt323(22))
                .foregroundColor(.black)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.lavenderQuick(for: appTheme))
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
        )
    }
}
