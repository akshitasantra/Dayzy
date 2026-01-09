import SwiftUI

struct QuickStartRow: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    let activities: [String]
    let disabled: Bool
    let onStart: (String) -> Void

    private let columns = [
        GridItem(.fixed(100), spacing: 6),
        GridItem(.fixed(100), spacing: 6)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(activities, id: \.self) { title in
                quickStartButton(for: title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenPadding)
    }

    // MARK: Button

    @ViewBuilder
    private func quickStartButton(for title: String) -> some View {
        Button {
            onStart(title)
        } label: {
            Text(title)
                .font(AppFonts.rounded(10))
                .foregroundColor(Color.black)
                .padding(.vertical, 12)
                .frame(width: 100)
                .background(AppColors.lavenderQuick(for: appTheme))
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColors.black(for: appTheme), lineWidth: 1)
                )
                .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)
                .opacity(disabled ? 0.5 : 1)
        }
        .withClickSound()
        .disabled(disabled)
    }
}
