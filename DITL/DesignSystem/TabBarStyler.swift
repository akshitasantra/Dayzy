import SwiftUI
import UIKit

struct DynamicTabBarStyler: UIViewControllerRepresentable {
    @ObservedObject var themeManager: ThemeManager

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        applyAppearance()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        applyAppearance()
    }

    private func applyAppearance() {
        let cardColor = UIColor(Color(hex: themeManager.theme.cardColorHex))
        let primaryColor = UIColor(Color(hex: themeManager.theme.primaryColorHex))
        let unselectedColor = UIColor.gray

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = cardColor

        // Selected
        appearance.stackedLayoutAppearance.selected.iconColor = primaryColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: primaryColor]

        // Unselected
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        // Apply globally
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Force currently visible tab bars to refresh immediately
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first,
              let tabBar = window.rootViewController?.children.compactMap({ $0 as? UITabBarController }).first?.tabBar
        else { return }

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.setNeedsLayout()
    }
}
