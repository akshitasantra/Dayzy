import SwiftUI

struct PeriodBarChart: View {
    private let cardBackground = AppColors.card()
    
    let current: [Int]      // e.g., this week/day totals
    let previous: [Int]     // previous week/day totals
    let labels: [String]    // day names or month numbers
    let scope: WrappedScope
    
    let colorCurrent: Color = AppColors.lavenderQuick()
    let colorPrevious: Color = AppColors.text(on: AppColors.card())

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<labels.count, id: \.self) { i in
                        VStack {
                            // Bars side by side
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(colorPrevious)
                                    .frame(
                                        height: scaledHeight(for: previous[i], geoHeight: geo.size.height)
                                    )
                                Rectangle()
                                    .fill(colorCurrent)
                                    .frame(
                                        height: scaledHeight(for: current[i], geoHeight: geo.size.height)
                                    )
                            }
                            .frame(maxWidth: .infinity)

                            // Label
                            Text(labels[i])
                                .font(.caption)
                                .rotationEffect(labels.count > 7 ? .degrees(-45) : .degrees(0))
                                .frame(height: 20)
                                .foregroundColor(AppColors.text(on: cardBackground))
                        }
                    }
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 24) {
                legendItem(color: colorCurrent, text: "This \(scope.rawValue.lowercased())")
                legendItem(color: colorPrevious, text: "Last \(scope.rawValue.lowercased())")
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

    private func scaledHeight(for value: Int, geoHeight: CGFloat) -> CGFloat {
        let maxVal = max((current + previous).max() ?? 1, 1)
        return CGFloat(value) / CGFloat(maxVal) * geoHeight * 0.8 // leave some top padding
    }
}
