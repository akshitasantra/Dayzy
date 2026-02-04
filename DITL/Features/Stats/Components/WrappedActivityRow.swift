import SwiftUI

struct WrappedActivityRow: View {
    @AppStorage("customThemeData") private var customThemeData: Data?
    
    let activity: Activity
    let minutes: Int

    var body: some View {
        HStack {
            // Activity title
            Text(activity.title)
                .font(AppFonts.rounded(18))
                .foregroundColor(Color.black)


            Spacer()

            // Duration
            Text("\(minutes) min")
                .font(AppFonts.vt323(22))
                .foregroundColor(Color.black)


        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.lavenderQuick())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}
