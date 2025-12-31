import SwiftUI

struct TimelineSection: View {
    let timeline: [Activity]
    let currentActivity: Activity?

    let onDelete: (Activity) -> Void
    let onEdit: (Activity) -> Void

    @State private var pendingDeleteId: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Add a clip & track your time here")
                .font(AppFonts.rounded(12))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            List {
                // Active activity (non-deletable)
                if let active = currentActivity {
                    TimelineEntryRow(
                        timeRange: formattedTimeRange(
                            start: active.startTime,
                            end: Date()
                        ),
                        activity: active.title
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(timeline.reversed()) { activity in
                    TimelineEntryRow(
                        timeRange: formattedTimeRange(
                            start: activity.startTime,
                            end: activity.endTime
                        ),
                        activity: activity.title
                    )
                    .onTapGesture(count: 2) {
                        onEdit(activity)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                onDelete(activity)
                                pendingDeleteId = nil
                            } label: {
                                Label("Confirm", systemImage: "trash.fill")
                            }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .frame(height: 140)
            .scrollContentBackground(.hidden)
            .background(AppColors.pinkCard)
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
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) – \(formatter.string(from: end ?? Date()))"
    }
}




struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No timeline entries yet")
                .font(AppFonts.vt323(20))
                .foregroundColor(AppColors.black)

            Text("Your completed activities will show up here!")
                .font(AppFonts.vt323(16))
                .foregroundColor(AppColors.black)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.pinkCard)
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}
