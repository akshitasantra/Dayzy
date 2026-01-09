import SwiftUI

enum AppTab {
    case today
    case stats
    case video
}

struct ContentView: View {
    // MARK: App State
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    @State private var selectedTab: AppTab = .today

    // MARK: UI State
    @State private var showingSettings = false
    @State private var showingManualStart = false
    @State private var settingsSourceTab: AppTab?

    // MARK: Activity State
    @State private var currentActivity: Activity?
    @State private var timeline: [Activity] = []
    @State private var editingActivity: Activity?
    @State private var addingActivity = false

    var body: some View {
        ZStack {
            tabView
            settingsOverlay
        }
        .preferredColorScheme(appTheme == .dark ? .dark : .light)
        .onAppear(perform: onAppear)
        .onChange(of: appTheme, applyTheme)
        .sheet(isPresented: $showingManualStart, content: manualStartSheet)
        .sheet(item: $editingActivity, content: editActivitySheet)
        .sheet(isPresented: $addingActivity, content: addActivitySheet)
    }
}

// MARK: Main Views
private extension ContentView {
    var tabView: some View {
        TabView(selection: $selectedTab) {

            TodayView(
                currentActivity: $currentActivity,
                timeline: $timeline,
                onSettingsTapped: { openSettings(from: .today) },
                onWrappedTapped: { selectedTab = .stats },
                onQuickStart: startActivity,
                onManualStartTapped: { showingManualStart = true },
                onEditTimelineEntry: { editingActivity = $0 },
                onAddTimelineEntry: { addingActivity = true },
                reloadToday: reloadToday
            )
            .tabItem { Label("Today", systemImage: "calendar") }
            .tag(AppTab.today)

            SQLDashboardView(
                onSettingsTapped: { openSettings(from: .stats) }
            )
            .tabItem { Label("Stats", systemImage: "chart.bar") }
            .tag(AppTab.stats)

            VideoView(
                onSettingsTapped: { openSettings(from: .video) }
            )
            .tabItem { Label("Video", systemImage: "video.fill") }
            .tag(AppTab.video)
        }
    }

    var settingsOverlay: some View {
        Group {
            if showingSettings {
                SettingsView {
                    showingSettings = false
                    if let source = settingsSourceTab {
                        selectedTab = source
                    }
                }
                .zIndex(1)
            }
        }
    }
}

// MARK: Sheets
private extension ContentView {
    func manualStartSheet() -> some View {
        ManualStartSheet { title in
            startActivity(title: title)
            showingManualStart = false
        }
    }

    func editActivitySheet(activity: Activity) -> some View {
        EditActivitySheet(activity: activity) { title, start, end in
            let duration = calculateDuration(start: start, end: end)

            DatabaseManager.shared.updateActivity(
                id: activity.id,
                newTitle: title,
                newStart: start,
                newEnd: end,
                newDuration: duration
            )

            reloadToday()
        }
    }

    func addActivitySheet() -> some View {
        let placeholder = Activity(
            id: -1,
            title: "",
            startTime: Date(),
            endTime: Date(),
            durationMinutes: 0
        )

        return EditActivitySheet(activity: placeholder) { title, start, end in
            let duration = calculateDuration(start: start, end: end)

            DatabaseManager.shared.createActivity(
                title: title,
                start: start,
                end: end,
                duration: duration
            )

            reloadToday()
        }
    }
}

// MARK: Helpers
private extension ContentView {
    func openSettings(from tab: AppTab) {
        settingsSourceTab = tab
        showingSettings = true
    }

    func onAppear() {
        TabBarStyler.apply(theme: appTheme)
        reloadToday()
    }

    func applyTheme(_: AppTheme, _ newTheme: AppTheme) {
        TabBarStyler.apply(theme: newTheme)
    }

    func calculateDuration(start: Date, end: Date) -> Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}

// MARK: Activity Logic
private extension ContentView {
    func reloadToday() {
        timeline = DatabaseManager.shared.fetchTodayActivities()
    }

    func startActivity(title: String) {
        guard currentActivity == nil else { return }

        currentActivity = Activity(
            id: -1,
            title: title,
            startTime: Date(),
            endTime: nil,
            durationMinutes: nil
        )
    }
}
