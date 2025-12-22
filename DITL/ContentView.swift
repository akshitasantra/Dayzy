import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Floating settings button
                HStack {
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppColors.black)
                        .padding(10)
                        .background(AppColors.lavenderQuick)
                        .clipShape(Circle())
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // Header block
                VStack(spacing: 10) {
                    Text("Today")
                        .font(AppFonts.vt323(42))
                        .foregroundColor(AppColors.pinkPrimary)

                    Text(formattedDate())
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.pinkPrimary)
                }
                .padding(.top, 43) // matches your Figma spacing

                // Current Activity Card
                CurrentActivityCard()
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                
                // Quick Start Row
                QuickStartRow()
                    .padding(.top, 24)
                
                // Timeline
                TimelineSection()
                
                Spacer()
            }
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: Date())
    }
}

#Preview {
    ContentView()
}
