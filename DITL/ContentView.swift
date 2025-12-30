import SwiftUI

// MARK: - Root View
struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingManualStart = false

    @State private var currentActivity: Activity? = nil
    @State private var timeline: [Activity] = []

    var body: some View {
        ZStack {
            if showingSettings {
                SettingsView {
                    showingSettings = false
                }
            } else {
                TodayView(
                    currentActivity: $currentActivity,
                    timeline: $timeline,
                    onSettingsTapped: {
                        showingSettings = true
                    },
                    onQuickStart: startActivity,
                    onManualStartTapped: {
                        showingManualStart = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingManualStart) {
            ManualStartSheet { title in
                startActivity(title: title)
                showingManualStart = false
            }
        }
    }

    // MARK: - Activity Actions
    private func startActivity(title: String) {
        guard currentActivity == nil else { return }

        currentActivity = Activity(
            title: title,
            startTime: Date(),
            endTime: nil
        )
    }
}


// MARK: - Today View
struct TodayView: View {
    @Binding var currentActivity: Activity?
    @Binding var timeline: [Activity]
    let onSettingsTapped: () -> Void
    let onQuickStart: (String) -> Void
    let onManualStartTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Settings Button
                HStack {
                    Spacer()
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
                                if let active = currentActivity {
                                    timeline.append(Activity(
                                        title: active.title,
                                        startTime: active.startTime,
                                        endTime: Date()
                                    ))
                                    currentActivity = nil
                                }
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
                        TimelineSection(timeline: timeline)
                    }
                }
                .padding(.top, 24)

                Spacer()
            }
        }
    }

    func formattedDate() -> String {
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
                // Back button
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

