import SwiftUI

struct PeriodBarChart: View {
    private let cardBackground = AppColors.card()
    
    let current: [Int]
    let previous: [Int]
    let labels: [String]
    let scope: WrappedScope
    
    let colorCurrent: Color = .black
    let colorPrevious: Color = AppColors.lavenderQuick()
    
    var body: some View {
        VStack(spacing: 12) {
            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<labels.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(colorPrevious)
                                .frame(height: barHeight(for: previous[i]))
                            Rectangle()
                                .fill(colorCurrent)
                                .frame(height: barHeight(for: current[i]))
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                        
                        // Label
                        Text(labels[i])
                            .font(.caption)
                            .rotationEffect(labels.count > 7 ? .degrees(-45) : .degrees(0))
                            .frame(height: 20)
                            .foregroundColor(AppColors.text(on: cardBackground))
                    }
                }
            }
            .frame(height: 200) // fixed chart height
            
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
        let maxHeight: CGFloat = 200
        return CGFloat(value) / CGFloat(maxVal) * maxHeight
    }
}
