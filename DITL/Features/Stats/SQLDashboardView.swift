import SwiftUI

struct SQLDashboardView: View {
    @State private var totalToday: Int = 0
    @State private var mostTimeConsuming: [(Activity, Int)] = []

@AppStorage("customThemeData") private var customThemeData: Data?


    
    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with settings button
                HStack {
                    Spacer()
                    
                    Button {
                        onSettingsTapped()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.black)


                            .padding(10)
                            .background(AppColors.lavenderQuick())
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // Header section
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("DITL Wrapped")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.primary())

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    Text("Your day, summarized")
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.primary())
                }
                .padding(.top, 12)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {

                        // Total Time Card
                        WrappedTotalTimeCard(totalMinutes: totalToday)

                        // Most Time-Consuming Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Time-Consuming Activities")
                                .font(AppFonts.vt323(28))
                                .foregroundColor(AppColors.text(on: AppColors.background()))

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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadSQLData()
        }
    }

    // MARK: Helpers
    private func loadSQLData() {
        let total = DatabaseManager.shared.totalTimeToday()
        let activities = DatabaseManager.shared.mostTimeConsumingActivitiesToday()

        DispatchQueue.main.async {
            self.totalToday = total
            self.mostTimeConsuming = Array(activities.prefix(5))
        }
    }
}
