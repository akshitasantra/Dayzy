import SwiftUI
import Combine

struct CurrentActivityCard: View {
    let activity: Activity
    let onEnd: () -> Void

    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Activity title
                Text(activity.title)
                    .font(AppFonts.vt323(24))
                    .foregroundColor(AppColors.pinkPrimary(for: appTheme))
                    .multilineTextAlignment(.center)

                // Started at
                Text("Started at \(formattedTime(activity.startTime))")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.black(for: appTheme))
                    .multilineTextAlignment(.center)

                // Elapsed time + video icon
                HStack(spacing: 8) {
                    Text("\(elapsedTimeString(elapsed)) elapsed")
                        .font(AppFonts.vt323(18))
                        .foregroundColor(AppColors.black(for: appTheme))

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
                Button(action: onEnd) {
                    Text("End Activity")
                        .font(AppFonts.rounded(24))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(AppColors.pinkPrimary(for: appTheme))
                        .cornerRadius(AppLayout.cornerRadius)
                }
                .withClickSound()
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColors.black(for: appTheme), lineWidth: 1)
                )
                .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.pinkCard(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
            .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)

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
        .onAppear {
            elapsed = Date().timeIntervalSince(activity.startTime)
        }
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(activity.startTime)
        }
    }

    // MARK: Helpers
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func elapsedTimeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

