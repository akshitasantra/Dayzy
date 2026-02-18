import SwiftUI
import Combine

struct CurrentActivityCard: View {
    let activity: Activity
    let onEnd: () -> Void

    private let cardBackground = AppColors.card()
    private let primaryBackground = AppColors.primary()

    @State private var videoSheet: VideoActionSheet?
    @State private var showVideoDialog = false
    @State private var elapsed: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VStack(spacing: 16) {

                Text(activity.title)
                    .font(AppFonts.vt323(24))
                    .foregroundColor(AppColors.primary())
                    .multilineTextAlignment(.center)

                Text("Started at \(formattedTime(activity.startTime))")
                    .font(AppFonts.rounded(24))
                    .foregroundColor(AppColors.text(on: cardBackground))

                HStack(spacing: 8) {
                    Text("\(elapsedTimeString(elapsed)) elapsed")
                        .font(AppFonts.vt323(18))
                        .foregroundColor(AppColors.text(on: cardBackground))

                    Button {
                        showVideoDialog = true
                    } label: {
                        Image(AppColors.text(on: cardBackground) == .white ? "video-white" : "video")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }

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

        .confirmationDialog(
            "Add Video",
            isPresented: $showVideoDialog
        ) {
            Button("Record Video") { videoSheet = .record }
            Button("Upload from Photos") { videoSheet = .upload }
            Button("Cancel", role: .cancel) {}
        }

        .sheet(item: $videoSheet) { sheet in
            switch sheet {
            case .record:
                VideoRecorderView(
                    onSaved: { assetId in
                        DatabaseManager.shared.addVideoClip(
                            activityId: activity.id,
                            assetId: assetId
                        )
                        videoSheet = nil
                    },
                    onCancel: { videoSheet = nil }
                )

            case .upload:
                VideoPickerView(
                    onPicked: { assetId in
                        DatabaseManager.shared.addVideoClip(
                            activityId: activity.id,
                            assetId: assetId
                        )
                        videoSheet = nil
                    },
                    onCancel: { videoSheet = nil }
                )
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func elapsedTimeString(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

