import SwiftUI

struct AppColors {

    static func card() -> Color {
        getColor(isPrimary: false, defaultHex: "#FBE3EB")
    }

    static func primary() -> Color {
        getColor(isPrimary: true, defaultHex: "#E88AB8")
    }

    static func text(on background: Color) -> Color {
        background.idealTextColor()
    }

    static func lavenderQuick() -> Color {
        Color(hex: "#E6D9FF")
    }

    static func background() -> Color {
        if let data = UserDefaults.standard.data(forKey: AppThemeKey.customTheme),
           let theme = try? JSONDecoder().decode(AppThemeData.self, from: data) {
            return theme.useDarkBackground
                ? Color(hex: "#2A2A28")
                : Color.white
        }
        return Color.white
    }

    private static func getColor(isPrimary: Bool, defaultHex: String) -> Color {
        if let data = UserDefaults.standard.data(forKey: AppThemeKey.customTheme),
           let theme = try? JSONDecoder().decode(AppThemeData.self, from: data) {
            return Color(hex: isPrimary ? theme.primaryColorHex : theme.cardColorHex)
        }
        return Color(hex: defaultHex)
    }
    
}
