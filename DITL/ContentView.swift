import SwiftUI

// MARK: - Root View
struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingWrapped = false
    @State private var showingManualStart = false
    @State private var editingActivity: Activity? = nil
    @State private var addingActivity: Bool = false

    @State private var currentActivity: Activity? = nil
    @State private var timeline: [Activity] = []

    var body: some View {
        ZStack {
            if showingSettings {
                SettingsView { showingSettings = false }
            }
            else if showingWrapped {
                SQLDashboardView{ showingWrapped = false }
            }
            else {
                TodayView(
                    currentActivity: $currentActivity,
                    timeline: $timeline,
                    onSettingsTapped: { showingSettings = true },
                    onWrappedTapped: { showingWrapped = true },
                    onQuickStart: startActivity,
                    onManualStartTapped: { showingManualStart = true },
                    onEditTimelineEntry: { activity in
                        editingActivity = activity
                    },
                    onAddTimelineEntry: {
                        addingActivity = true
                    },
                    reloadToday: reloadToday
                )
            }
        }
        .onAppear {
            reloadToday()
        }
        .sheet(isPresented: $showingManualStart) {
            ManualStartSheet { title in
                startActivity(title: title)
                showingManualStart = false
            }
        }
        .sheet(item: $editingActivity) { activity in
            EditActivitySheet(activity: activity) { newTitle, newStart, newEnd in
                let duration = Int(newEnd.timeIntervalSince(newStart) / 60)

                DatabaseManager.shared.updateActivity(
                    id: activity.id,
                    newTitle: newTitle,
                    newEnd: newEnd,
                    newDuration: duration
                )

                reloadToday()
                addingActivity = false
            }
        }
        .sheet(isPresented: $addingActivity) {
                    let dummyActivity = Activity(
                        id: -1,
                        title: "",
                        startTime: Date(),
                        endTime: Date(),
                        durationMinutes: 0
                    )
                    EditActivitySheet(activity: dummyActivity) { newTitle, newStart, newEnd in
                        let duration = Int(newEnd.timeIntervalSince(newStart) / 60)
                        DatabaseManager.shared.createActivity(
                            title: newTitle,
                            start: newStart,
                            end: newEnd,
                            duration: duration
                        )
                        reloadToday()
                        addingActivity = false
                    }
                }
    }

    // MARK: - DB Sync
    private func reloadToday() {
        timeline = DatabaseManager.shared.fetchTodayActivities()
    }

    // MARK: - Activity Actions
    private func startActivity(title: String) {
        guard currentActivity == nil else { return }

        currentActivity = Activity(
            id: -1, // temp ID for in-progress activity
            title: title,
            startTime: Date(),
            endTime: nil,
            durationMinutes: nil
        )
    }
}


// MARK: - Today View
struct TodayView: View {
    @Binding var currentActivity: Activity?
    @Binding var timeline: [Activity]

    let onSettingsTapped: () -> Void
    let onWrappedTapped: () -> Void
    let onQuickStart: (String) -> Void
    let onManualStartTapped: () -> Void
    let onEditTimelineEntry: (Activity) -> Void
    let onAddTimelineEntry: () -> Void
    let reloadToday: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    // Wrapped Button on the left
                    Button(action: onWrappedTapped) {
                        Image(systemName: "list.clipboard")
                            .foregroundColor(AppColors.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Settings Button on the right
                    Button(action: onSettingsTapped) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppColors.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // Header
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("Today")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary)

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    Text(formattedDate())
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.pinkPrimary)
                }

                // Current Activity
                Group {
                    if let activity = currentActivity {
                        CurrentActivityCard(
                            activity: activity,
                            onEnd: {
                                let end = Date()
                                let duration = Int(end.timeIntervalSince(activity.startTime) / 60)

                                DatabaseManager.shared.createActivity(
                                    title: activity.title,
                                    start: activity.startTime,
                                    end: end,
                                    duration: duration
                                )

                                reloadToday()
                            }
                        )
                    } else {
                        NoActivityCard(
                            onStartTapped: onManualStartTapped
                        )
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, AppLayout.screenPadding)

                // Quick Start
                QuickStartRow(
                    disabled: currentActivity != nil,
                    onStart: onQuickStart
                )
                .padding(.top, 16)

                // Timeline
                VStack(spacing: 12) {
                    Text("Today’s Timeline")
                        .font(AppFonts.vt323(40))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    if timeline.isEmpty {
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
                            onEdit: { activity in
                                onEditTimelineEntry(activity)
                            }
                        )
                    }
                }
                .padding(.top, 24)

                Spacer()
                
                Button {
                        onAddTimelineEntry()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .padding(8)
                            .background(AppColors.lavenderQuick)
                            .clipShape(Circle())
                    }
            }
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd · EEEE · h:mm a"
        return f.string(from: Date())
    }
}


// MARK: - Settings View
struct SettingsView: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                VStack(spacing: 32) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("Settings")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary)

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    PreferencesCard()
                    AboutSection()
                }
                .padding(.top, 43)
                .padding(.horizontal, AppLayout.screenPadding)

                Spacer()
            }
        }
    }
}

// MARK: - SQLDashboard
struct SQLDashboardView: View {
    @State private var totalToday: Int = 0
    @State private var mostTimeConsuming: [(Activity, Int)] = []

    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Back Button (matches Settings)
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // Header (matches Today / Settings)
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("DITL Wrapped")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary)

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    Text("Your day, summarized")
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.pinkPrimary)
                }
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {

                        // Total Time Card
                        WrappedTotalTimeCard(totalMinutes: totalToday)

                        // Most Time-Consuming Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Time-Consuming Activities")
                                .font(AppFonts.vt323(28))
                                .foregroundColor(AppColors.black)

                            ForEach(mostTimeConsuming, id: \.0.id) { activity, minutes in
                                WrappedActivityRow(
                                    activity: activity,
                                    minutes: minutes
                                )
                            }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                }

                Spacer()
            }
        }
        .onAppear {
            loadSQLData()
        }
    }

    private func loadSQLData() {
        totalToday = DatabaseManager.shared.totalTimeToday()
        mostTimeConsuming = Array(
            DatabaseManager.shared
                .mostTimeConsumingActivities()
                .prefix(5)
        )
    }
}
