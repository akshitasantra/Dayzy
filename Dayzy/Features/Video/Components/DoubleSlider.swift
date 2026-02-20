import SwiftUI

struct DoubleSlider: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let range: ClosedRange<Double>
    var onEditingChanged: (() -> Void)? = nil  // callback when drag ends

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.blue)
                    .frame(
                        width: CGFloat((upperValue - lowerValue) / (range.upperBound - range.lowerBound)) * geo.size.width,
                        height: 4
                    )
                    .offset(x: CGFloat((lowerValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geo.size.width)

                // Lower handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .offset(x: CGFloat((lowerValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geo.size.width - 14)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newVal = range.lowerBound + Double(value.location.x / geo.size.width) * (range.upperBound - range.lowerBound)
                                lowerValue = min(max(range.lowerBound, newVal), upperValue)
                            }
                            .onEnded { _ in onEditingChanged?() }
                    )

                // Upper handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .offset(x: CGFloat((upperValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geo.size.width - 14)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newVal = range.lowerBound + Double(value.location.x / geo.size.width) * (range.upperBound - range.lowerBound)
                                upperValue = max(lowerValue, min(range.upperBound, newVal))
                            }
                            .onEnded { _ in onEditingChanged?() }
                    )
            }
        }
        .frame(height: 40)
    }
}
