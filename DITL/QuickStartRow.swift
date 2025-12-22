import SwiftUI

struct QuickStartRow: View {

    let buttons = ["Homework", "Scroll", "Code", "Eat"] // Example button labels

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(buttons, id: \.self) { title in
                Text(title)
                    .font(AppFonts.rounded(12)) // slightly bigger for fit
                    .foregroundColor(AppColors.black)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.lavenderQuick)
                    .cornerRadius(AppLayout.cornerRadius)
                    // Black outline
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                            .stroke(Color.black.opacity(1.0), lineWidth: 1)
                    )
                    // Drop shadow
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }
}

#Preview {
    ZStack {
        AppColors.background
        QuickStartRow()
            .padding(.top, 20)
    }
}
