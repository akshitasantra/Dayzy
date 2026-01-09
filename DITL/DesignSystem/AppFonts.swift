import SwiftUI

enum AppFonts {
    // VT323
    static func vt323(_ size: CGFloat) -> Font {
        .custom("VT323-Regular", size: size)
    }

    // SF Compact Rounded
    static func rounded(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}
