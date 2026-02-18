import SwiftUI

struct TimelineEntryRow: View {
    let activityId: Int
    let timeRange: String
    let activity: String

    @State private var videoSheet: VideoActionSheet?
    @State private var showVideoDialog = false

    private let bg = AppColors.card()

    var body: some View {
        HStack(spacing: 24) {
            Text(timeRange)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .frame(width: 160, alignment: .leading)

            Text(activity)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showVideoDialog = true
            } label: {
                Image(AppColors.text(on: bg) == .white ? "video-white" : "video")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
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
                            activityId: activityId,
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
                            activityId: activityId,
                            assetId: assetId
                        )
                        videoSheet = nil
                    },
                    onCancel: { videoSheet = nil }
                )
            }
        }
    }
}


