import SwiftUI

struct TimelineSection: View {
    let timeline: [Activity]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Caption
            Text("Add a clip & track your time here")
                .font(AppFonts.rounded(12))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Timeline Card
            VStack {
                if timeline.isEmpty {
                    EmptyTimelineView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(timeline) { activity in
                                TimelineEntryRow(
                                    timeRange: formattedTimeRange(for: activity),
                                    activity: activity.title
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(height: 140)
            .background(AppColors.pinkCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.10),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
    }

    private func formattedTimeRange(for activity: Activity) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let start = formatter.string(from: activity.startTime)
        let end = activity.endTime != nil ? formatter.string(from: activity.endTime!) : "…"
        return "\(start) – \(end)"
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
