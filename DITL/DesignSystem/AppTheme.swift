import SwiftUI

// MARK: - AppTheme
struct AppThemeData: Codable {
    var cardColorHex: String = "#FBE3EB"
    var primaryColorHex: String = "#E88AB8"
    var useDarkBackground: Bool = false
}

enum AppThemeKey {
    static let customTheme = "customAppTheme"
}
