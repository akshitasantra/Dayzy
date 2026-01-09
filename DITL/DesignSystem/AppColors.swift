import SwiftUI

enum AppColors {
    static func pinkCard(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#FBE3EB") : Color(hex: "#E88AB8")
    }
    static func pinkPrimary(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#E88AB8") : Color(hex:"#FADBE6")
    }
    static func lavenderQuick(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#E6D9FF") : Color(hex: "#E6D9FF")
    }
    static func background(for theme: AppTheme) -> Color {
        theme == .light ? Color(hex: "#FFF9F5") : Color(hex: "#2A2A28")
    }
    static func white(for theme: AppTheme) -> Color {
        theme == .light ? Color.white : Color.black
    }
    static func black(for theme: AppTheme) -> Color {
        theme == .light ? Color.black : Color.white
    }
}
