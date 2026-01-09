import SwiftUI
import UIKit

struct TabBarStyler {

    static func apply(theme: AppTheme) {
        let lavender = UIColor(AppColors.pinkPrimary(for: theme))
        let unselected = UIColor.gray

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = UIColor(
            AppColors.background(for: theme)
        )

        // Selected
        appearance.stackedLayoutAppearance.selected.iconColor = lavender
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: lavender
        ]

        // Unselected
        appearance.stackedLayoutAppearance.normal.iconColor = unselected
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselected
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
