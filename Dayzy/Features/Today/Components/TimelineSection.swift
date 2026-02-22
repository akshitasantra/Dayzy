import SwiftUI

struct TimelineSection: View {
    let timeline: [Activity]
    let currentActivity: Activity?
    let onDelete: (Activity) -> Void
    let onEdit: (Activity) -> Void
    let reloadToday: () -> Void

    @AppStorage("customThemeData") private var customThemeData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a clip & track your time here")
                .font(AppFonts.rounded(12))
                .foregroundColor(AppColors.text(on: AppColors.background()))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 12) {
                        if let active = currentActivity {
                            TimelineEntryRow(
                                activity: active,
                                timeRange: formattedTimeRange(start: active.startTime, end: active.endTime),
                                onClipSaved: reloadToday,
                                onDelete: onDelete
                            )
                            .onTapGesture(count: 2) { onEdit(active) }
                        }

                        ForEach(timeline.reversed()) { activity in
                            TimelineEntryRow(
                                activity: activity,
                                timeRange: formattedTimeRange(start: activity.startTime, end: activity.endTime),
                                onClipSaved: reloadToday,
                                onDelete: onDelete
                            )
                            .onTapGesture(count: 2) { onEdit(activity) }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
            }
            .background(AppColors.card())
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
    }

    private func formattedTimeRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end ?? Date()))"
    }
}


// MARK: Empty Timeline Placeholder
struct EmptyTimelineView: View {
    @AppStorage("customThemeData") private var customThemeData: Data?

    private let bg = AppColors.card()
    var body: some View {
        VStack(spacing: 8) {
            Text("No timeline entries yet")
                .font(AppFonts.vt323(20))
                .foregroundColor(AppColors.text(on: bg))
            Text("Your completed activities will show up here!")
                .font(AppFonts.vt323(16))
                .foregroundColor(AppColors.text(on: bg))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.card())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }
}
