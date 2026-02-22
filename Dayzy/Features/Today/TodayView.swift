import SwiftUI

struct TodayView: View {
    // MARK: Bindings
    @Binding var currentActivity: Activity?
    @Binding var timeline: [Activity]
    
    let todayClips: [ClipMetadata]

    // MARK: App Theme
    @AppStorage("customThemeData") private var customThemeData: Data?

    @State private var showDayPreview = false
    @State private var previewClips: [ClipMetadata] = []

    // MARK: Callbacks
    let onSettingsTapped: () -> Void
    let onWrappedTapped: () -> Void
    let onQuickStart: (String) -> Void
    let onManualStartTapped: () -> Void
    let onEditTimelineEntry: (Activity) -> Void
    let onAddTimelineEntry: () -> Void
    let reloadToday: () -> Void

    // MARK: Defaults
    private let defaultQuickStarts = ["Homework", "Scroll", "Code", "Eat"]

    // MARK: Body
    var body: some View {
        ZStack {
            AppColors.background()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Settings Button
                    HStack {
                        Spacer()
                        Button(action: onSettingsTapped) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(AppColors.text(on: AppColors.lavenderQuick()))

                                .padding(10)
                                .background(AppColors.lavenderQuick())
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, AppLayout.screenPadding)

                    // MARK: Header
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image("star")
                                .resizable()
                                .rotationEffect(.degrees(45))
                                .frame(width: 24, height: 24)

                            Text("Today")
                                .font(AppFonts.vt323(42))
                                .foregroundColor(AppColors.primary())

                            Image("star")
                                .resizable()
                                .rotationEffect(.degrees(45))
                                .frame(width: 24, height: 24)
                        }

                        Text(formattedDate())
                            .font(AppFonts.rounded(16))
                            .foregroundColor(AppColors.primary())
                    }

                    // MARK: Current Activity Card
                    Group {
                        if let activity = currentActivity {
                            CurrentActivityCard(
                                activity: activity,
                                onEnd: endCurrentActivity,
                                onClipSaved: reloadToday
                            )
                        } else {
                            NoActivityCard(
                                onStartTapped: onManualStartTapped
                            )
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)

                    // MARK: Quick Start Row
                    QuickStartRow(
                        activities: resolvedQuickStarts(),
                        disabled: currentActivity != nil,
                        onStart: onQuickStart
                    )
                    .padding(.top, 16)

                    // MARK: Timeline Section
                    VStack(spacing: 12) {
                        Text("Today’s Timeline")
                            .font(AppFonts.vt323(40))
                            .foregroundColor(AppColors.text(on: AppColors.background()))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        let displayTimeline: [Activity] = currentActivity.map { timeline + [$0] } ?? timeline

                        if displayTimeline.isEmpty {
                            EmptyTimelineView()
                                .padding(.horizontal, AppLayout.screenPadding)
                        } else {
                            TimelineSection(
                                timeline: timeline,
                                currentActivity: currentActivity,
                                onDelete: { activity in
                                    DatabaseManager.shared.deleteActivity(id: activity.id)
                                    reloadToday()
                                },
                                onEdit: onEditTimelineEntry,
                                reloadToday: reloadToday
                            )
                        }
                    }
                    .padding(.top, 24)

                    Spacer(minLength: 24)

                    // MARK: Add Timeline Entry Button
                    Button(action: onAddTimelineEntry) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.text(on: AppColors.lavenderQuick()))

                            .padding(8)
                            .background(AppColors.lavenderQuick())
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    


    // MARK: Helpers

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd · EEEE · h:mm a"
        return formatter.string(from: Date())
    }

    private func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        DatabaseManager.shared.endActivity(activity)

        currentActivity = nil
        timeline = DatabaseManager.shared.fetchTodayActivities()
    }

    private func resolvedQuickStarts() -> [String] {
        let top = DatabaseManager.shared.topQuickStartActivities()

        guard top.count < 4 else { return top }

        let remaining = defaultQuickStarts.filter { !top.contains($0) }
        return top + remaining.prefix(4 - top.count)
    }
}
