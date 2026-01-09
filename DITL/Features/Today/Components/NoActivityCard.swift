import SwiftUI

struct NoActivityCard: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let onStartTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main card
            Text("No Activity Running")
                .font(AppFonts.rounded(24))
                .foregroundColor(AppColors.black(for: appTheme))
                .multilineTextAlignment(.center)

            Text("Start something to begin tracking!")
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.black(for: appTheme))
            
            Button(action: onStartTapped) {
                            Text("Start Activity")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.white(for: appTheme))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(AppColors.pinkPrimary(for: appTheme))
                    .cornerRadius(AppLayout.cornerRadius)
            }.withClickSound()
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.pinkCard(for: appTheme))
        .cornerRadius(AppLayout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
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
