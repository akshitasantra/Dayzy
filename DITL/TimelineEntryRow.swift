import SwiftUI

struct TimelineEntryRow: View {
    let timeRange: String
    let activity: String

    var body: some View {
        HStack(alignment: .center, spacing: 24) {

            // Time column
            Text(timeRange)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.black)
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            // Activity name
            Text(activity)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.black)
                .lineLimit(1)

            Spacer()
        }
    }
}
