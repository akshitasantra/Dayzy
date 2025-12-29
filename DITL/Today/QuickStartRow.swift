import SwiftUI

struct QuickStartRow: View {

    let buttons = ["Homework", "Scroll", "Code", "Eat"] // Example button labels

    let columns = [
        GridItem(.fixed(100), spacing: 6),
        GridItem(.fixed(100), spacing: 6)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(buttons, id: \.self) { title in
                Text(title)
                    .font(AppFonts.rounded(10))
                    .foregroundColor(AppColors.black)
                    .padding(.vertical, 12)
                    .frame(width: 100)
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
        .frame(maxWidth: .infinity, alignment: .center)
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

