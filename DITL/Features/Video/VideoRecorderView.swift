import SwiftUI
import UIKit
import Photos

struct VideoRecorderView: UIViewControllerRepresentable {
    let onSaved: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              UIImagePickerController.availableMediaTypes(for: .camera)?.contains("public.movie") == true
        else {
            // Fallback to photo library (or handle gracefully)
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            return picker
        }

        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeMedium
        picker.cameraCaptureMode = .video

        return picker
    }


    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSaved: onSaved, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onSaved: (String) -> Void
        let onCancel: () -> Void

        init(onSaved: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onSaved = onSaved
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            guard let url = info[.mediaURL] as? URL else {
                picker.dismiss(animated: true)
                return
            }

            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized || status == .limited else { return }

                var assetId = ""

                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    assetId = request?.placeholderForCreatedAsset?.localIdentifier ?? ""
                }) { success, _ in
                    DispatchQueue.main.async {
                        picker.dismiss(animated: true)
                        if success {
                            self.onSaved(assetId)
                        }
                    }
                }
            }
        }
    }
}
