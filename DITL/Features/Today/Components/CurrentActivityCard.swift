import SwiftUI
import Combine

struct CurrentActivityCard: View {
    let activity: Activity
    let onEnd: () -> Void
    
    private let cardBackground = AppColors.card()
    private let primaryBackground = AppColors.primary()
    
    @State private var showingRecorder = false
    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
@AppStorage("customThemeData") private var customThemeData: Data?


    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Activity title
                Text(activity.title)
                    .font(AppFonts.vt323(24))
                    .foregroundColor(AppColors.primary())
                    .multilineTextAlignment(.center)

                // Started at
                Text("Started at \(formattedTime(activity.startTime))")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.text(on: cardBackground))
                    .multilineTextAlignment(.center)

                // Elapsed time + video icon
                HStack(spacing: 8) {
                    Text("\(elapsedTimeString(elapsed)) elapsed")
                        .font(AppFonts.vt323(18))
                        .foregroundColor(AppColors.text(on: cardBackground))

                    Button {
                        showingRecorder = true
                    } label: {
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
                        .background(AppColors.primary())
                        .cornerRadius(AppLayout.cornerRadius)
                }
                .withClickSound()
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(Color.black, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.card())
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
        .onAppear {
            elapsed = Date().timeIntervalSince(activity.startTime)
        }
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(activity.startTime)
        }
        .sheet(isPresented: $showingRecorder) {
            VideoRecorderView(
                onSaved: { assetId in
                    DatabaseManager.shared.addVideoClip(
                        activityId: activity.id,
                        assetId: assetId
                    )
                },
                onCancel: {}
            )
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

