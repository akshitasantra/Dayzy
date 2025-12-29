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
                VStack(spacing: 4) {
                    // Stars + Today text in one line
                    HStack(spacing: 8) { // small spacing between stars and text
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(90))
                            .frame(width: 24, height: 24)

                        Text("Today")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary)

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(90))
                            .frame(width: 24, height: 24)
                    }

                    // Date below
                    Text(formattedDate())
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.pinkPrimary)
                }

                // Current Activity Card
                CurrentActivityCard()
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                
                // Quick Start Row
                QuickStartRow()
                    .padding(.top, 16)
                
                // Timeline
                TimelineSection()
                
                Spacer()
            }
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd · EEEE · h:mm a"
        return f.string(from: Date())
    }

}

#Preview {
    ContentView()
}
