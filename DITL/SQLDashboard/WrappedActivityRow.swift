import SwiftUI

struct WrappedActivityRow: View {
    let activity: Activity
    let minutes: Int

    var body: some View {
        HStack {
            Text(activity.title)
                .font(AppFonts.rounded(18))
                .foregroundColor(AppColors.black)

            Spacer()

            Text("\(minutes) min")
                .font(AppFonts.vt323(22))
                .foregroundColor(AppColors.black)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.lavenderQuick)
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}
