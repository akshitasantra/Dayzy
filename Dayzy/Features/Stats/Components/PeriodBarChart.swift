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
    
    var body: some View {
        VStack(spacing: 6) {
            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<labels.count, id: \.self) { i in
                    let currentValue = i < current.count ? current[i] : 0
                    let previousValue = i < previous.count ? previous[i] : 0
                    HStack(alignment: .bottom, spacing: 2) {
                        Rectangle()
                            .fill(colorCurrent)
                            .frame(height: barHeight(for: currentValue))
                        Rectangle()
                            .fill(colorPrevious)
                            .frame(height: barHeight(for: previousValue))
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
        // Use max of both periods to normalize
        let maxVal = max((current + previous).max() ?? 1, 1)
        return CGFloat(value) / CGFloat(maxVal) * chartHeight
    }
}
