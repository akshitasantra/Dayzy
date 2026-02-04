import SwiftUI
import UIKit

struct TabBarStyler {

    static func apply(cardColor: Color, primaryColor: Color) {
        let lavender = UIColor(primaryColor)
        let unselected = UIColor.gray

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = UIColor(cardColor)

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
