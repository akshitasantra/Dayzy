import SwiftUI

struct NoActivityCard: View {
    @AppStorage("customThemeData") private var customThemeData: Data?
    
    let onStartTapped: () -> Void
    private let cardBackground = AppColors.card()
    
    var body: some View {
        VStack(spacing: 12) {
            // Main card
            Text("No Activity Running")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.text(on: cardBackground))
                .multilineTextAlignment(.center)

            Text("Start something to begin tracking!")
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: cardBackground))
            
            Button(action: onStartTapped) {
                            Text("Start Activity")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.text(on: AppColors.primary()))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(AppColors.primary())
                    .cornerRadius(AppLayout.cornerRadius)
            }.withClickSound()
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.card())
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.black, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        
        // Decorative corner icons
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
