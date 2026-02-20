import SwiftUI

struct Asset: Identifiable, Equatable {
    let id: String  // This will hold the assetId string
}

struct TimelineEntryRow: View {
    let activity: Activity
    let timeRange: String

    @State private var showRecorder = false
    @State private var showPicker = false
    @State private var editingAssetId: String? = nil
    @State private var editingAsset: Asset? = nil

    private let bg = AppColors.card()

    var body: some View {
        HStack(spacing: 24) {
            Text(timeRange)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .frame(width: 160, alignment: .leading)

            Text(activity.title)
                .font(AppFonts.vt323(18))
                .foregroundColor(AppColors.text(on: bg))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                // Show the "Record / Upload" choices
                showVideoDialog()
            } label: {
                Image(AppColors.text(on: bg) == .white ? "video-white" : "video")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
        // 🎥 Recorder
        .fullScreenCover(isPresented: $showRecorder) {
            VideoRecorderView(
                onSaved: { assetId in
                    showRecorder = false
                    editingAsset = Asset(id: assetId)
                },
                onCancel: {
                    showRecorder = false
                }
            )
        }

        // 📁 Picker
        .sheet(isPresented: $showPicker) {
            VideoPickerView(
                onPicked: { assetId in
                    showPicker = false
                    editingAsset = Asset(id: assetId)
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
        // ✂️ Clip Editor
        // ✂️ Clip Editor
        .sheet(item: $editingAsset) { asset in
            ClipEditorView(
                assetId: asset.id,
                activityName: activity.title,
                activityStart: activity.startTime,
                onSaved: { newAssetId, metadata in
                    editingAsset = nil
                    // TODO: save metadata
                },
                onCancel: {
                    editingAsset = nil
                }
            )
        }
    }

    // Helper function to show the Record/Upload options
    private func showVideoDialog() {
        let alert = UIAlertController(title: "Add Video", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Record Video", style: .default) { _ in
            showRecorder = true
        })
        alert.addAction(UIAlertAction(title: "Upload from Photos", style: .default) { _ in
            showPicker = true
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(alert, animated: true)
        }
    }
}
