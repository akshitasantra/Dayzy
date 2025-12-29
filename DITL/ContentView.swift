import SwiftUI

// MARK: Root View
struct ContentView: View {
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            if showingSettings {
                SettingsView {
                    // Back action
                    showingSettings = false
                }
            } else {
                TodayView {
                    // Settings button tapped
                    showingSettings = true
                }
            }
        }
    }
}

// MARK: Today View
struct TodayView: View {
    var onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating settings button
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

                // Header block
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

                // Current Activity Card
                CurrentActivityCard()
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                
                // Quick Start Row
                QuickStartRow()
                    .padding(.top, 16)
                
                // Timeline
                TimelineSection()
                
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

// MARK: Settings View
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

