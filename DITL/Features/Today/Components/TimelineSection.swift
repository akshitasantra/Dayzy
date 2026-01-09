import SwiftUI

struct TimelineSection: View {
    let timeline: [Activity]
    let currentActivity: Activity?
    let onDelete: (Activity) -> Void
    let onEdit: (Activity) -> Void

    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header
            Text("Add a clip & track your time here")
                .font(AppFonts.rounded(12))
                .foregroundColor(AppColors.black(for: appTheme))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Timeline list
            List {
                // Active activity
                if let active = currentActivity {
                    TimelineEntryRow(
                        timeRange: formattedTimeRange(start: active.startTime, end: Date()),
                        activity: active.title
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                // Completed activities
                ForEach(timeline.reversed()) { activity in
                    TimelineEntryRow(
                        timeRange: formattedTimeRange(start: activity.startTime, end: activity.endTime),
                        activity: activity.title
                    )
                    .onTapGesture(count: 2) { onEdit(activity) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { onDelete(activity) } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(maxWidth: .infinity)
            .frame(height: listHeight)
            .background(AppColors.pinkCard(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
    }

    // MARK: Helpers
    private func formattedTimeRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end ?? Date()))"
    }

    private var listHeight: CGFloat {
        let rowCount = (currentActivity == nil ? 0 : 1) + timeline.count
        return max(CGFloat(rowCount) * 52.5, 50)
    }
}

// MARK: Empty Timeline Placeholder
struct EmptyTimelineView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    var body: some View {
        VStack(spacing: 8) {
            Text("No timeline entries yet")
                .font(AppFonts.vt323(20))
                .foregroundColor(AppColors.black(for: appTheme))

            Text("Your completed activities will show up here!")
                .font(AppFonts.vt323(16))
                .foregroundColor(AppColors.black(for: appTheme))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.pinkCard(for: appTheme))
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }
}
