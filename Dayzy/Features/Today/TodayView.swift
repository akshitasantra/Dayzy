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
    @State private var selectedDate: Date = Date()


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
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }


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
                    VStack(spacing: 6) {
                        HStack {
                            Button {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                                reloadForSelectedDate()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(AppColors.primary())
                            }

                            Spacer()

                            VStack(spacing: 4) {
                                Text(isToday ? "Today" : formattedDate(selectedDate))
                                    .font(AppFonts.vt323(42))
                                    .foregroundColor(AppColors.primary())

                                if isToday {
                                    Text(formattedDate())
                                        .font(AppFonts.rounded(16))
                                        .foregroundColor(AppColors.primary())
                                }
                            }

                            Spacer()

                            Button {
                                guard !isToday else { return }
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                                reloadForSelectedDate()
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .opacity(isToday ? 0.3 : 1)
                                    .foregroundColor(AppColors.primary())
                            }
                            .disabled(isToday)
                        }
                    }
                    .padding(.horizontal, AppLayout.screenPadding)


                    // MARK: Current Activity Card
                    Group {
                        if isToday {
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
                        } else {
                            // Past day placeholder
                            VStack {
                                Text("This day has already ended!")
                                    .font(AppFonts.rounded(16))
                                    .foregroundColor(AppColors.text(on: AppColors.card()))
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.card())
                            .cornerRadius(AppLayout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)

                    // MARK: Quick Start Row
                    QuickStartRow(
                        activities: resolvedQuickStarts(),
                        disabled: !isToday || currentActivity != nil,
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
                                currentActivity: isToday ? currentActivity : nil,
                                onDelete: { activity in
                                    DatabaseManager.shared.deleteActivity(id: activity.id)
                                    reloadForSelectedDate()
                                },
                                onEdit: onEditTimelineEntry,
                                reloadToday: reloadForSelectedDate
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

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
    
    private func reloadForSelectedDate() {
        if isToday {
            timeline = DatabaseManager.shared.fetchTodayActivities()
            currentActivity = DatabaseManager.shared.fetchCurrentActivity()
        } else {
            timeline = DatabaseManager.shared.fetchActivities(for: selectedDate)
            currentActivity = nil
        }
    }

}
