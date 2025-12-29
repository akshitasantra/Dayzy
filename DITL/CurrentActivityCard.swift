import SwiftUI

struct CurrentActivityCard: View {
    var body: some View {
        ZStack {
            // Card background + content
            VStack(spacing: 16) {

                // Activity title
                Text("Homework")
                    .font(AppFonts.vt323(24))
                    .foregroundColor(AppColors.pinkPrimary)
                    .multilineTextAlignment(.center)

                // Started at
                Text("Started at 8:12 AM")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.black)
                    .multilineTextAlignment(.center)

                // Elapsed time + video icon
                HStack(spacing: 8) {
                    Text("01:35 elapsed")
                        .font(AppFonts.vt323(18))
                        .foregroundColor(AppColors.black)

                    Button(action: {
                        // TODO: record clip
                    }) {
                        Image("video")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }
                .multilineTextAlignment(.center)

                // End Activity Button
                Button(action: {}) {
                    Text("End Activity")
                        .font(AppFonts.rounded(24))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(AppColors.pinkPrimary)
                        .cornerRadius(AppLayout.cornerRadius)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(Color.black, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)

            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.pinkCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
            // Decorative icons anchored to card corners
            .overlay(alignment: .topLeading) {
                Image("love")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .bottomTrailing) {
                Image("love")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                Image("love-always-wins")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                Image("love-always-wins")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background
        CurrentActivityCard()
            .padding()
    }
}
