import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager() // singleton for easy access

    @Published var theme: AppThemeData {
        didSet {
            saveTheme(theme)
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: AppThemeKey.customTheme),
           let decoded = try? JSONDecoder().decode(AppThemeData.self, from: data) {
            self.theme = decoded
        } else {
            self.theme = AppThemeData(
                cardColorHex: "#FBE3EB",
                primaryColorHex: "#E88AB8"
            )
        }
    }

    private func saveTheme(_ theme: AppThemeData) {
        if let data = try? JSONEncoder().encode(theme) {
            UserDefaults.standard.set(data, forKey: AppThemeKey.customTheme)
        }
    }

    func update(cardColor: Color? = nil, primaryColor: Color? = nil, useDarkBackground: Bool? = nil) {
        var newTheme = theme
        if let cardColor = cardColor { newTheme.cardColorHex = cardColor.toHex() }
        if let primaryColor = primaryColor { newTheme.primaryColorHex = primaryColor.toHex() }
        if let useDark = useDarkBackground { newTheme.useDarkBackground = useDark }
        theme = newTheme
    }
}
