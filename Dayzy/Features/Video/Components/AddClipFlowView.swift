import SwiftUI
import Photos

struct AddClipFlowView: View {
    let activityName: String
    let activityStart: Date

    @State private var showRecorder = false
    @State private var showPicker = false
    @State private var editingAsset: EditingAsset?
    @State private var showDayPreview = false
    @State private var previewClips: [ClipMetadata] = []

    var body: some View {
        VStack(spacing: 16) {
            Button("Record Video") {
                showRecorder = true
            }

            Button("Upload Video") {
                showPicker = true
            }

            Divider().padding(.vertical, 12)

            Button("Preview Day") {
                previewClips = DatabaseManager.shared.fetchClipsForToday()
                showDayPreview = true
            }
            .disabled(DatabaseManager.shared.fetchClipsForToday().isEmpty)
        }

        // Recorder
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

        // Picker
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

        // Clip Editor
        .sheet(item: $editingAsset) { asset in
            ClipEditorView(
                assetId: asset.id,
                activityName: activityName,
                activityStart: activityStart,
                onSaved: { savedAssetId, metadata in
                    // 1) persist metadata + associate with activity
                    DatabaseManager.shared.saveClipMetadataAndAssociate(
                        assetId: savedAssetId,
                        metadata: metadata,
                        activityTitle: activityName,
                        activityStartApprox: activityStart
                    )

                    // 2) close editor and open day preview
                    editingAsset = nil

                    // refresh preview clips for today's view and present
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        previewClips = DatabaseManager.shared.fetchClipsForToday()
                        showDayPreview = true
                    }
                },
                onCancel: {
                    editingAsset = nil
                }
            )
        }

        // Day preview + export (re-uses your StitcherView)
        .sheet(isPresented: $showDayPreview) {
            StitcherView(
                clips: previewClips,
                onExported: { newAssetId in
                    // handle exported asset id (e.g. show confirmation / save DB)
                    showDayPreview = false
                },
                onCancel: {
                    showDayPreview = false
                }
            )
        }
        .padding()
    }
}
