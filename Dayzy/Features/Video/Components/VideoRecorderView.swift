import SwiftUI
import AVFoundation
import Photos

struct VideoRecorderView: UIViewControllerRepresentable {
    let onSaved: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VideoRecorderController {
        let controller = VideoRecorderController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VideoRecorderController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSaved: onSaved, onCancel: onCancel)
    }

    class Coordinator: NSObject, VideoRecorderControllerDelegate {
        let onSaved: (String) -> Void
        let onCancel: () -> Void

        init(onSaved: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onSaved = onSaved
            self.onCancel = onCancel
        }

        func videoRecorderDidCancel(_ recorder: VideoRecorderController) {
            onCancel()
        }

        func videoRecorder(_ recorder: VideoRecorderController, didFinishRecordingTo url: URL) {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized || status == .limited else { return }

                var assetId = ""

                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    assetId = request?.placeholderForCreatedAsset?.localIdentifier ?? ""
                }) { success, _ in
                    DispatchQueue.main.async {
                        if success {
                            self.onSaved(assetId)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - VideoRecorderController

protocol VideoRecorderControllerDelegate: AnyObject {
    func videoRecorderDidCancel(_ recorder: VideoRecorderController)
    func videoRecorder(_ recorder: VideoRecorderController, didFinishRecordingTo url: URL)
}

class VideoRecorderController: UIViewController {
    weak var delegate: VideoRecorderControllerDelegate?

    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let movieOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var recordButton: UIButton!
    private var timerLabel: UILabel!
    private var recordingTimer: Timer?
    private var secondsElapsed = 0
    private var isRecording = false
    
    @objc private func flipCamera() {
        guard let currentInput = videoDeviceInput else { return }

        session.beginConfiguration()
        session.removeInput(currentInput)

        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice),
              session.canAddInput(newInput) else {
            session.addInput(currentInput) // fallback
            session.commitConfiguration()
            return
        }

        session.addInput(newInput)
        videoDeviceInput = newInput
        session.commitConfiguration()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupPreview()
        setupButtons()
        setupTimerLabel()
        session.startRunning()
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput)
        else { return }

        session.addInput(videoInput)
        self.videoDeviceInput = videoInput

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
    }

    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(flipCamera))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }


    private func setupButtons() {
        // Existing recordButton
        recordButton = UIButton(type: .system)
        recordButton.frame = CGRect(x: view.bounds.midX - 35, y: view.bounds.height - 150, width: 70, height: 70)
        recordButton.backgroundColor = .red
        recordButton.layer.cornerRadius = 35
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.layer.borderWidth = 2
        recordButton.layer.borderColor = UIColor.white.cgColor
        view.addSubview(recordButton)

        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.frame = CGRect(x: 20, y: 50, width: 60, height: 40)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Flip camera button like Apple Camera
        let flipButtonSize: CGFloat = 50
        let flipButton = UIButton(type: .system)
        flipButton.frame = CGRect(x: view.bounds.width - flipButtonSize - 20,
                                  y: view.bounds.height - flipButtonSize - 150,
                                  width: flipButtonSize,
                                  height: flipButtonSize)
        
        // Make circular, semi-transparent background
        flipButton.backgroundColor = UIColor(white: 0.2, alpha: 0.5)
        flipButton.layer.cornerRadius = flipButtonSize / 2
        
        // Add SF Symbol icon
        let flipImage = UIImage(systemName: "arrow.triangle.2.circlepath.camera")
        flipButton.setImage(flipImage, for: .normal)
        flipButton.tintColor = .white
        
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        view.addSubview(flipButton)
    }

    private func setupTimerLabel() {
        timerLabel = UILabel(frame: CGRect(x: view.bounds.width - 100, y: 50, width: 80, height: 40))
        timerLabel.textColor = .red
        timerLabel.font = .boldSystemFont(ofSize: 20)
        timerLabel.textAlignment = .right
        timerLabel.text = "00:00"
        timerLabel.isHidden = true
        view.addSubview(timerLabel)
    }

    @objc private func toggleRecording() {
        if !isRecording {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            isRecording = true
            animateRecordingButton(isRecording: true)
            startTimer()
            startPulseAnimation()
        } else {
            movieOutput.stopRecording()
            isRecording = false
            animateRecordingButton(isRecording: false)
            stopTimer()
            stopPulseAnimation()
        }
    }

    private func animateRecordingButton(isRecording: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.recordButton.backgroundColor = isRecording ? .systemRed : .red
            self.recordButton.transform = isRecording ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
        }
    }

    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.5
        pulse.duration = 0.6
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        recordButton.layer.add(pulse, forKey: "pulseAnimation")
    }

    private func stopPulseAnimation() {
        recordButton.layer.removeAnimation(forKey: "pulseAnimation")
    }

    private func startTimer() {
        secondsElapsed = 0
        timerLabel.text = "00:00"
        timerLabel.isHidden = false
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.secondsElapsed += 1
            let minutes = self.secondsElapsed / 60
            let seconds = self.secondsElapsed % 60
            self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        timerLabel.isHidden = true
    }

    @objc private func cancelPressed() {
        session.stopRunning()
        delegate?.videoRecorderDidCancel(self)
        dismiss(animated: true)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension VideoRecorderController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        session.stopRunning()
        delegate?.videoRecorder(self, didFinishRecordingTo: outputFileURL)
        dismiss(animated: true)
    }
}
