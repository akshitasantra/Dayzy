import SwiftUI

enum AppColors {
    static let background = Color(hex: "#FFF9F5")
    static let pinkPrimary = Color(hex: "#E88AB8")
    static let pinkCard = Color(hex: "#FBE3EB")
    static let lavenderQuick = Color(hex: "#E6D9FF")
    static let black = Color.black
    static let white = Color.white
}

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

enum AppLayout {
    static let cornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 20
}

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "#RRGGBBAA" (alpha optional).
    /// If parsing fails, defaults to clear.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Accept 6 (RGB) or 8 (RGBA) characters
        var rgba: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgba) else {
            self = .clear
            return
        }

        let r, g, b, a: Double
        switch hexString.count {
        case 6:
            r = Double((rgba & 0xFF0000) >> 16) / 255.0
            g = Double((rgba & 0x00FF00) >> 8) / 255.0
            b = Double(rgba & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgba & 0xFF000000) >> 24) / 255.0
            g = Double((rgba & 0x00FF0000) >> 16) / 255.0
            b = Double((rgba & 0x0000FF00) >> 8) / 255.0
            a = Double(rgba & 0x000000FF) / 255.0
        default:
            self = .clear
            return
        }

        self = Color(red: r, green: g, blue: b, opacity: a)
    }
}

