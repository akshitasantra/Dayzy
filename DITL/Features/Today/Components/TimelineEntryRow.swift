import SwiftUI

struct TimelineEntryRow: View {
    @AppStorage("customThemeData") private var customThemeData: Data?

    
    let timeRange: String
    let activity: String
    
    private let bg = AppColors.card()

    var body: some View {
        HStack(alignment: .center, spacing: 24) {

            // Time
            Text(timeRange)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            // Activity name
            Text(activity)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .lineLimit(1)
                .truncationMode(.tail)       // adds "..." only if necessary
                .layoutPriority(1)           // gives this text priority to expand
                .frame(maxWidth: .infinity, alignment: .leading)

            // Video button
            Button(action: {
                // TODO: record clip
            }) {
                Image(AppColors.text(on: bg) == .white ? "video-white" : "video")
                        .resizable()
                        .frame(width: 20, height: 20)
            }
        }
    }
}
