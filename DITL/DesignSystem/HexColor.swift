import SwiftUI
import UIKit

extension Color {

    // MARK: - Init from Hex
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

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

    // MARK: - Convert to Hex
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }

    // MARK: - Relative Luminance
    private var luminance: CGFloat {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        func adjust(_ value: CGFloat) -> CGFloat {
            return value <= 0.03928
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * adjust(r)
             + 0.7152 * adjust(g)
             + 0.0722 * adjust(b)
    }

    // MARK: - Automatic Accessible Text Color
    /// Returns black or white depending on contrast
    func idealTextColor() -> Color {
        luminance > 0.5 ? .black : .white
    }
}
