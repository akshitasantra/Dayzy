import SwiftUI

struct CurrentActivityCard: View {
    var body: some View {
        VStack(spacing: 12) {

            // Activity title
            Text("Homework")
                .font(AppFonts.vt323(24))
                .foregroundColor(AppColors.pinkPrimary)

            // Started at
            Text("Started at 8:12 AM")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.black)

            // Elapsed time
            Text("01:35 elapsed")
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.black)

        }
        .multilineTextAlignment(.center)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.pinkCard)
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

#Preview {
    ZStack {
        AppColors.background
        CurrentActivityCard()
            .padding()
    }
}
