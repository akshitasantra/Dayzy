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
                    onPrevious: { offset += 1; load() },
                    onNext: { offset = max(0, offset - 1); load() },
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
        let previousStats = DatabaseManager.shared.stats(for: scope, offset: offset + 1)
        previousMinutes = previousStats.total

        // Compute biggest day if year view
        if scope == .year {
            let range = periodRange(for: .year, offset: offset, calendar: Calendar.current)
            let yearActivities = DatabaseManager.shared.fetchActivities(in: range.start, end: range.end)
            computeBiggestDay(from: yearActivities)
        } else {
            biggestDay = nil
        }
        
        loadChartData()
        headerTitle = generateHeaderTitle()
    }

    private func computeBiggestDay(from activities: [Activity]) {
        var dayTotals: [Date: Int] = [:]
        let calendar = Calendar.current

        for activity in activities {
            var cursor = activity.startTime
            let end = activity.endTime ?? cursor

            while cursor < end {
                let dayStart = calendar.startOfDay(for: cursor)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let sliceEnd = min(dayEnd, end)

                let minutes = Int(sliceEnd.timeIntervalSince(cursor) / 60)
                if minutes > 0 {
                    dayTotals[dayStart, default: 0] += minutes
                }

                cursor = sliceEnd
            }
        }

        if let (date, minutes) = dayTotals.max(by: { $0.value < $1.value }) {
            biggestDay = (date, minutes)
        } else {
            biggestDay = nil
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
        let currentRange = periodRange(for: scope, offset: offset, calendar: calendar)
        let previousRange = periodRange(for: scope, offset: offset + 1, calendar: calendar)

        let currentActivities = DatabaseManager.shared.fetchActivities(in: currentRange.start, end: currentRange.end)
        let previousActivities = DatabaseManager.shared.fetchActivities(in: previousRange.start, end: previousRange.end)

        switch scope {
        case .week:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            chartLabels = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: currentRange.start)
            }.map { formatter.string(from: $0) }

            currentPeriodTotals = dailyTotals(
                for: currentActivities,
                start: currentRange.start,
                days: 7,
                calendar: calendar
            )
            previousPeriodTotals = dailyTotals(
                for: previousActivities,
                start: previousRange.start,
                days: 7,
                calendar: calendar
            )

        case .month:
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentRange.start))!
            let previousMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousRange.start))!

            let currentDays = calendar.range(of: .day, in: .month, for: currentMonthStart)?.count ?? 30
            let previousDays = calendar.range(of: .day, in: .month, for: previousMonthStart)?.count ?? 30

            let currentDayTotals = dailyTotals(
                for: currentActivities,
                start: currentMonthStart,
                days: currentDays,
                calendar: calendar
            )
            let previousDayTotals = dailyTotals(
                for: previousActivities,
                start: previousMonthStart,
                days: previousDays,
                calendar: calendar
            )

            let currentWeekCount = weekCount(in: currentMonthStart, calendar: calendar)
            let previousWeekCount = weekCount(in: previousMonthStart, calendar: calendar)
            let weekCount = max(currentWeekCount, previousWeekCount)

            chartLabels = (1...weekCount).map { "Week \($0)" }
            currentPeriodTotals = weekTotals(
                dayTotals: currentDayTotals,
                monthStart: currentMonthStart,
                weekCount: weekCount,
                calendar: calendar
            )
            previousPeriodTotals = weekTotals(
                dayTotals: previousDayTotals,
                monthStart: previousMonthStart,
                weekCount: weekCount,
                calendar: calendar
            )


        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            chartLabels = formatter.shortMonthSymbols

            let currentYearStart = calendar.date(from: calendar.dateComponents([.year], from: currentRange.start))!
            let previousYearStart = calendar.date(from: calendar.dateComponents([.year], from: previousRange.start))!

            currentPeriodTotals = monthlyTotals(
                for: currentActivities,
                start: currentYearStart,
                months: 12,
                calendar: calendar
            )
            previousPeriodTotals = monthlyTotals(
                for: previousActivities,
                start: previousYearStart,
                months: 12,
                calendar: calendar
            )
        }
    }

    private func periodRange(for scope: WrappedScope, offset: Int, calendar: Calendar) -> (start: Date, end: Date) {
        let now = Date()
        switch scope {
        case .week:
            let base = calendar.date(byAdding: .weekOfYear, value: -offset, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .month:
            let base = calendar.date(byAdding: .month, value: -offset, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: base))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .year:
            let base = calendar.date(byAdding: .year, value: -offset, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year], from: base))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }

    private func dailyTotals(for activities: [Activity], start: Date, days: Int, calendar: Calendar) -> [Int] {
        var totals = Array(repeating: 0, count: days)
        let startDay = calendar.startOfDay(for: start)

        for activity in activities {
            var cursor = activity.startTime
            let end = activity.endTime ?? cursor

            while cursor < end {
                let dayStart = calendar.startOfDay(for: cursor)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let sliceEnd = min(dayEnd, end)

                let minutes = Int(sliceEnd.timeIntervalSince(cursor) / 60)
                if minutes > 0 {
                    let index = calendar.dateComponents([.day], from: startDay, to: dayStart).day ?? -1
                    if index >= 0 && index < totals.count {
                        totals[index] += minutes
                    }
                }

                cursor = sliceEnd
            }
        }

        return totals
    }

    private func weekCount(in monthStart: Date, calendar: Calendar) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return 4 }
        var maxWeek = 1
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                maxWeek = max(maxWeek, calendar.component(.weekOfMonth, from: date))
            }
        }
        return maxWeek
    }

    private func weekTotals(dayTotals: [Int], monthStart: Date, weekCount: Int, calendar: Calendar) -> [Int] {
        var totals = Array(repeating: 0, count: weekCount)
        let days = dayTotals.count
        guard days > 0 else { return totals }

        for day in 1...days {
            if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                let weekIndex = calendar.component(.weekOfMonth, from: date) - 1
                if weekIndex >= 0 && weekIndex < totals.count {
                    totals[weekIndex] += dayTotals[day - 1]
                }
            }
        }
        return totals
    }

    private func monthlyTotals(for activities: [Activity], start: Date, months: Int, calendar: Calendar) -> [Int] {
        var totals = Array(repeating: 0, count: months)
        let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!

        for activity in activities {
            var cursor = activity.startTime
            let end = activity.endTime ?? cursor

            while cursor < end {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: cursor))!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                let sliceEnd = min(monthEnd, end)

                let minutes = Int(sliceEnd.timeIntervalSince(cursor) / 60)
                if minutes > 0 {
                    let index = calendar.dateComponents([.month], from: startMonth, to: monthStart).month ?? -1
                    if index >= 0 && index < totals.count {
                        totals[index] += minutes
                    }
                }

                cursor = sliceEnd
            }
        }

        return totals
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
