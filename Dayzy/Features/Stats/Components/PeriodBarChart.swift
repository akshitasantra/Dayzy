import SwiftUI

struct PeriodBarChart: View {
    private let cardBackground = AppColors.card()
    private let chartHeight: CGFloat = 180
    private let labelHeight: CGFloat = 18

    let current: [Int]
    let previous: [Int]
    let labels: [String]
    let scope: WrappedScope

    let colorCurrent: Color = .black
    let colorPrevious: Color = AppColors.lavenderQuick()

    @State private var selectedBar: SelectedBar?
    
    private var allowsTooltip: Bool {
        scope != .year
    }

    struct SelectedBar: Equatable {
        let index: Int
        let isCurrent: Bool
        let value: Int
    }

    var body: some View {
        VStack(spacing: 6) {

            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<labels.count, id: \.self) { i in
                    let currentValue = i < current.count ? current[i] : 0
                    let previousValue = i < previous.count ? previous[i] : 0

                    HStack(alignment: .bottom, spacing: 2) {

                        // CURRENT BAR
                        barView(
                            value: currentValue,
                            color: colorCurrent,
                            selected: selectedBar == SelectedBar(index: i, isCurrent: true, value: currentValue)
                        )
                        .onLongPressGesture(minimumDuration: 0.2) {
                            guard allowsTooltip else { return }

                            withAnimation(.spring(duration: 0.2)) {
                                selectedBar = SelectedBar(
                                    index: i,
                                    isCurrent: true,
                                    value: currentValue
                                )
                            }
                        }

                        // PREVIOUS BAR
                        barView(
                            value: previousValue,
                            color: colorPrevious,
                            selected: selectedBar == SelectedBar(index: i, isCurrent: false, value: previousValue)
                        )
                        .onLongPressGesture(minimumDuration: 0.2) {
                            guard allowsTooltip else { return }

                            withAnimation(.spring(duration: 0.2)) {
                                selectedBar = SelectedBar(
                                    index: i,
                                    isCurrent: false,
                                    value: previousValue
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: chartHeight)
            .overlay(
                Rectangle()
                    .fill(AppColors.text(on: cardBackground).opacity(0.12))
                    .frame(height: 1),
                alignment: .bottom
            )
            .onTapGesture {
                // tap anywhere to dismiss tooltip
                withAnimation(.easeOut(duration: 0.15)) {
                    selectedBar = nil
                }
            }

            // Labels
            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<labels.count, id: \.self) { i in
                    Text(labels[i])
                        .font(.caption)
                        .rotationEffect(labels.count > 7 ? .degrees(-45) : .degrees(0))
                        .frame(maxWidth: .infinity)
                        .frame(height: labelHeight)
                        .foregroundColor(AppColors.text(on: cardBackground))
                }
            }

            // Legend
            HStack(spacing: 24) {
                legendItem(color: colorCurrent, text: "Current \(scope.displayName)")
                legendItem(color: colorPrevious, text: "Previous \(scope.displayName)")
            }
        }
    }

    private func barView(value: Int, color: Color, selected: Bool) -> some View {
        ZStack(alignment: .top) {

            Rectangle()
                .fill(color)
                .frame(height: max(barHeight(for: value), 4))
                .scaleEffect(selected ? 1.08 : 1.0)
                .animation(.spring(duration: 0.2), value: selected)

            if selected && allowsTooltip {
                Text(formatMinutes(value))
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                    .foregroundColor(.black)
                    .offset(y: -28)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.text(on: cardBackground))
        }
    }

    private func barHeight(for value: Int) -> CGFloat {
        let maxVal = max((current + previous).max() ?? 1, 1)
        return CGFloat(value) / CGFloat(maxVal) * chartHeight
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
