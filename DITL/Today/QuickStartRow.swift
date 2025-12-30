import SwiftUI

struct QuickStartRow: View {

    let buttons = ["Homework", "Scroll", "Code", "Eat"]
    let disabled: Bool
    let onStart: (String) -> Void

    let columns = [
        GridItem(.fixed(100), spacing: 6),
        GridItem(.fixed(100), spacing: 6)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(buttons, id: \.self) { title in
                Button {
                    onStart(title)
                } label: {
                    Text(title)
                        .font(AppFonts.rounded(10))
                        .foregroundColor(AppColors.black)
                        .padding(.vertical, 12)
                        .frame(width: 100)
                        .background(AppColors.lavenderQuick)
                        .cornerRadius(AppLayout.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
                        .opacity(disabled ? 0.5 : 1)
                }
                .disabled(disabled)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenPadding)
    }
}
