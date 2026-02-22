import SwiftUI
import UIKit

struct TimelineEntryRow: View {
    let activity: Activity
    let timeRange: String
    let onClipSaved: () -> Void
    let onDelete: (Activity) -> Void

    @State private var showRecorder = false
    @State private var showPicker = false
    @State private var editingAsset: EditingAsset? = nil

    // swipe state
    @State private var offsetX: CGFloat = 0
    @State private var isOpen: Bool = false

    private let bg = AppColors.card()
    private let deleteWidth: CGFloat = 50

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background / Delete button
            HStack {
                Spacer()
                Button(action: {
                    // close UI then call delete
                    withAnimation { openClose(false) }
                    // small delay to allow animation to feel snappy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        onDelete(activity)
                    }
                }) {
                    VStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Delete")
                            .font(AppFonts.rounded(10))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteWidth, height: 30)
                }
                .background(Color.red)
                .cornerRadius(8)
                .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Foreground content (the row)
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
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(AppColors.card())
            .cornerRadius(10)
            .offset(x: offsetX)
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { v in
                        // If vertical drag is larger, ignore — let the outer ScrollView handle it.
                        if abs(v.translation.height) > abs(v.translation.width) { return }
                        var newX = v.translation.width + (isOpen ? -deleteWidth : 0)
                        // constrain
                        newX = min(0, newX)
                        newX = max(-deleteWidth - 8, newX)
                        offsetX = newX
                    }
                    .onEnded { v in
                        // if gesture ends, decide to open or close
                        let predicted = v.predictedEndTranslation.width + (isOpen ? -deleteWidth : 0)
                        let threshold: CGFloat = -(deleteWidth / 2)
                        if predicted < threshold || v.translation.width < -deleteWidth/2 {
                            openClose(true)
                        } else {
                            openClose(false)
                        }
                    }
            )
            // close when tapping the row if it's open
            .onTapGesture {
                if isOpen {
                    openClose(false)
                }
            }
        }
        .padding(.horizontal, 4)
        .animation(.interactiveSpring(), value: offsetX)
        // Recorder / Picker / Editor sheets
        .fullScreenCover(isPresented: $showRecorder) {
            VideoRecorderView(
                onSaved: { assetId in
                    showRecorder = false
                    editingAsset = EditingAsset(id: assetId)
                },
                onCancel: {
                    showRecorder = false
                }
            )
        }
        .sheet(isPresented: $showPicker) {
            VideoPickerView(
                onPicked: { assetId in
                    showPicker = false
                    editingAsset = EditingAsset(id: assetId)
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
        .sheet(item: $editingAsset) { asset in
            ClipEditorView(
                assetId: asset.id,
                activityName: activity.title,
                activityStart: activity.startTime,
                onSaved: { newAssetId, metadata in
                    DatabaseManager.shared.addVideoClip(
                        activityId: activity.id,
                        assetId: newAssetId,
                        metadata: metadata
                    )
                    editingAsset = nil
                    onClipSaved()
                },
                onCancel: {
                    editingAsset = nil
                }
            )
        }
    }

    private func openClose(_ open: Bool) {
        isOpen = open
        offsetX = open ? -deleteWidth - 8 : 0
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
