import SwiftUI

struct TextOverlayPreviewView: View {
    let text: String
    let fontName: String
    let scale: CGFloat
    let color: Color
    let relativePosition: CGPoint
    @Binding var dragOffset: CGSize

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.custom(fontName, size: (min(geo.size.width, geo.size.height) * 0.08 * scale)))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .frame(width: geo.size.width * 0.9)
                .position(x: relativePosition.x * geo.size.width + dragOffset.width,
                          y: relativePosition.y * geo.size.height + dragOffset.height)
                .shadow(radius: 2)
        }
    }
}

