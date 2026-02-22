import SwiftUI

struct SQLDashboardView: View {
    @State private var scope: WrappedScope = .week
    @State private var offset: Int = 0
    @State private var biggestDay: (date: Date, minutes: Int)? = nil
    @State private var totalMinutes: Int = 0
    @State private var previousMinutes: Int? = nil  // ← Add this
    @State private var activities: [(Activity, Int)] = []
    @State private var headerTitle: String = ""
    @State private var chartLabels: [String] = []
    @State private var currentPeriodTotals: [Int] = []
    @State private var previousPeriodTotals: [Int] = []

    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background().ignoresSafeArea()

            VStack(spacing: 20) {

                // Settings
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


                // Wrapped title
                Text("Dayzy Summary")
                    .font(AppFonts.vt323(42))
                    .foregroundColor(AppColors.primary())

                // Scope tabs
                Picker("", selection: $scope) {
                    ForEach(WrappedScope.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: scope) { _ in
                    offset = 0
                    load()
                }

                // Period header
                var isCurrentPeriod: Bool {
                    offset == 0
                }

                WrappedPeriodHeader(
                    title: headerTitle,
                    onPrevious: { offset -= 1; load() },
                    onNext: { offset += 1; load() },
                    disableNext: isCurrentPeriod
                )


                ScrollView {
                    VStack(spacing: 24) {

                        WrappedTotalTimeCard(totalMinutes: totalMinutes, previousMinutes: previousMinutes, scope: scope)

                        PeriodBarChart(
                            current: currentPeriodTotals,
                            previous: previousPeriodTotals,
                            labels: chartLabels,
                            scope: scope
                        )
                        
                        PeriodTrendsCard(
                            totalMinutes: totalMinutes,
                            previousMinutes: previousMinutes ?? 0,
                            scope: scope
                        )
                        
                        if scope == .year, let biggest = biggestDay {
                            BiggestDayCard(date: biggest.date, minutes: biggest.minutes)
                                .padding(.vertical, 8)
                        }

                        VStack(spacing: 12) {
                            Text("Top Activities")
                                .font(AppFonts.vt323(28))
                                .frame(maxWidth: .infinity, alignment: .center) // Centered header

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(activities.prefix(5), id: \.0.id) {
                                    WrappedActivityRow(activity: $0.0, minutes: $0.1)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let stats = DatabaseManager.shared.stats(for: scope, offset: offset)
        totalMinutes = stats.total
        activities = stats.activities
        headerTitle = stats.title

        // Calculate previous period
        let previousStats = DatabaseManager.shared.stats(for: scope, offset: offset - 1)
        previousMinutes = previousStats.total

        // Compute biggest day if year view
        if scope == .year {
            computeBiggestDay(from: stats.activities)
        } else {
            biggestDay = nil
        }
        
        loadChartData()
        headerTitle = generateHeaderTitle()
    }

    private func computeBiggestDay(from activities: [(Activity, Int)]) {
        var dayTotals: [Date: Int] = [:]
        let calendar = Calendar.current

        for (activity, minutes) in activities {
            let day = calendar.startOfDay(for: activity.startTime)
            dayTotals[day, default: 0] += minutes
        }

        if let (date, minutes) = dayTotals.max(by: { $0.value < $1.value }) {
            biggestDay = (date, minutes)
        }
    }

    private func generateHeaderTitle() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        switch scope {
        case .week:
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -offset, to: today)!
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            return "\(formattedDate(weekStart)) – \(formattedDate(weekEnd))"
        case .month:
            let monthStart = calendar.date(byAdding: .month, value: -offset, to: today)!
            let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
            let end = calendar.date(byAdding: .day, value: monthRange.count - 1, to: start)!
            return "\(formattedDate(start)) – \(formattedDate(end))"
        case .year:
            let yearStart = calendar.date(byAdding: .year, value: -offset, to: today)!
            let start = calendar.date(from: calendar.dateComponents([.year], from: yearStart))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return "\(formattedDate(start)) – \(formattedDate(end))"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }


    private func loadChartData() {
        // Clear previous data
        chartLabels = []
        currentPeriodTotals = []
        previousPeriodTotals = []

        let calendar = Calendar.current

        switch scope {
        case .week:
            // Determine start of the current week based on offset
            guard let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -offset, to: calendar.startOfDay(for: Date())) else { return }
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek))!

            // Previous week start
            let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!

            chartLabels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
            currentPeriodTotals = Array(repeating: 0, count: 7)
            previousPeriodTotals = Array(repeating: 0, count: 7)

            let statsCurrent = DatabaseManager.shared.stats(for: .week, offset: offset)
            let statsPrev = DatabaseManager.shared.stats(for: .week, offset: offset - 1)

            for (activity, minutes) in statsCurrent.activities {
                let dayIndex = calendar.component(.weekday, from: activity.startTime) - 2
                let index = (dayIndex < 0 ? 6 : dayIndex) // Sun -> 6
                currentPeriodTotals[index] += minutes
            }

            for (activity, minutes) in statsPrev.activities {
                let dayIndex = calendar.component(.weekday, from: activity.startTime) - 2
                let index = (dayIndex < 0 ? 6 : dayIndex)
                previousPeriodTotals[index] += minutes
            }

        case .month:
            // Current month start
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: calendar.startOfDay(for: Date())) else { return }
            
            // Get number of weeks in month
            let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!
            let numDays = monthRange.count
            
            // Map each day to week index
            var weekIndices: [Int] = []
            for day in 1...numDays {
                if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                    let weekOfMonth = calendar.component(.weekOfMonth, from: date) - 1 // 0-based
                    weekIndices.append(weekOfMonth)
                }
            }
            
            let numWeeks = weekIndices.max() ?? 3 // number of weeks in month
            currentPeriodTotals = Array(repeating: 0, count: numWeeks + 1)
            previousPeriodTotals = Array(repeating: 0, count: numWeeks + 1)
            chartLabels = (0...numWeeks).map { "Week \($0 + 1)" }

            let statsCurrent = DatabaseManager.shared.stats(for: .month, offset: offset)
            let statsPrev = DatabaseManager.shared.stats(for: .month, offset: offset - 1)

            for (activity, minutes) in statsCurrent.activities {
                let weekIndex = calendar.component(.weekOfMonth, from: activity.startTime) - 1
                currentPeriodTotals[weekIndex] += minutes
            }

            for (activity, minutes) in statsPrev.activities {
                let weekIndex = calendar.component(.weekOfMonth, from: activity.startTime) - 1
                previousPeriodTotals[weekIndex] += minutes
            }


        case .year:
            // Current year
            guard let yearStart = calendar.date(byAdding: .year, value: -offset, to: calendar.startOfDay(for: Date())) else { return }

            chartLabels = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
            currentPeriodTotals = Array(repeating: 0, count: 12)
            previousPeriodTotals = Array(repeating: 0, count: 12)

            let statsCurrent = DatabaseManager.shared.stats(for: .year, offset: offset)
            let statsPrev = DatabaseManager.shared.stats(for: .year, offset: offset - 1)

            for (activity, minutes) in statsCurrent.activities {
                let month = calendar.component(.month, from: activity.startTime)
                currentPeriodTotals[month - 1] += minutes
            }

            for (activity, minutes) in statsPrev.activities {
                let month = calendar.component(.month, from: activity.startTime)
                previousPeriodTotals[month - 1] += minutes
            }
        }
    }
}

func formatMinutes(_ totalMinutes: Int) -> String {
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 {
        return "\(hours) h \(minutes) min"
    } else {
        return "\(minutes) min"
    }
}

