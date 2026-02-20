import SwiftUI
import AVFoundation
import Photos
import UIKit

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
// Minimal Identifiable wrapper (you already added this in prior messages)
struct EditingAsset: Identifiable {
    let id: String
}

// Keep your ClipMetadata as-is (re-use)
struct ClipMetadata: Codable {
    var assetId: String
    var suggestedText: String
    var fontName: String
    var fontScale: CGFloat
    var position: CGPoint
    var colorHex: String
    var trimmedStart: CMTime
    var trimmedDuration: CMTime

    enum CodingKeys: String, CodingKey {
        case assetId, suggestedText, fontName, fontScale, position, colorHex, trimmedStart, trimmedDuration
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assetId, forKey: .assetId)
        try container.encode(suggestedText, forKey: .suggestedText)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(fontScale, forKey: .fontScale)
        try container.encode(position, forKey: .position)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(CMTimeGetSeconds(trimmedStart), forKey: .trimmedStart)
        try container.encode(CMTimeGetSeconds(trimmedDuration), forKey: .trimmedDuration)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assetId = try container.decode(String.self, forKey: .assetId)
        suggestedText = try container.decode(String.self, forKey: .suggestedText)
        fontName = try container.decode(String.self, forKey: .fontName)
        fontScale = try container.decode(CGFloat.self, forKey: .fontScale)
        position = try container.decode(CGPoint.self, forKey: .position)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        let startSec = try container.decode(Double.self, forKey: .trimmedStart)
        let durSec = try container.decode(Double.self, forKey: .trimmedDuration)
        trimmedStart = CMTime(seconds: startSec, preferredTimescale: 600)
        trimmedDuration = CMTime(seconds: durSec, preferredTimescale: 600)
    }

    init(
        assetId: String,
        suggestedText: String,
        fontName: String,
        fontScale: CGFloat,
        position: CGPoint,
        colorHex: String,
        trimmedStart: CMTime,
        trimmedDuration: CMTime
    ) {
        self.assetId = assetId
        self.suggestedText = suggestedText
        self.fontName = fontName
        self.fontScale = fontScale
        self.position = position
        self.colorHex = colorHex
        self.trimmedStart = trimmedStart
        self.trimmedDuration = trimmedDuration
    }
}

// MARK: - ClipEditorView (two-step: trim -> overlay)
struct ClipEditorView: View {
    let assetId: String
    let activityName: String
    let activityStart: Date
    let onSaved: (String, ClipMetadata) -> Void   // returns new assetId and metadata
    let onCancel: () -> Void

    // UI state
    @State private var avAsset: AVAsset?
    @State private var duration: Double = 0.0
    @State private var startTrim: Double = 0.0
    @State private var endTrim: Double = 0.0   // seconds (end)
    @State private var player: AVPlayer? = nil

    // Editor overlay state
    @State private var text: String = ""
    @State private var fontName: String = "HelveticaNeue-Bold"
    @State private var fontScale: CGFloat = 1.0
    @State private var position: CGPoint = CGPoint(x: 0.5, y: 0.5) // relative center
    @State private var color: Color = .white

    // gestures
    @State private var dragOffset: CGSize = .zero
    @State private var pinchScale: CGFloat = 1.0

    // UI flow
    @State private var showingStep: EditorStep = .trim
    @State private var showFontOptions: Bool = false
    @FocusState private var textFieldFocused: Bool
    @State private var timeObserverToken: Any?
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // fonts to choose from
    private let fonts = ["HelveticaNeue-Bold", "Avenir-Heavy", "Georgia-Bold", "Menlo-Bold"]

    enum EditorStep {
        case trim
        case overlay
    }

    var body: some View {
        ZStack {
            // MARK: - Video Preview (full screen)
            GeometryReader { geo in
                if let player = player {
                    ZStack {
                        VideoPlayerView(player: player)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .onAppear { player.play() }

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation { showFontOptions.toggle() }
                            }
                    }

                } else {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .edgesIgnoringSafeArea(.all)

            // MARK: - Floating controls (bottom)
            // Overlay controls (showingStep == .overlay)
            if showingStep == .overlay {
                ZStack {
                    // Fullscreen dragable text
                    TextOverlayPreviewView(
                        text: text,
                        fontName: fontName,
                        scale: fontScale * pinchScale,
                        color: color,
                        relativePosition: position,
                        dragOffset: $dragOffset
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { showFontOptions.toggle() }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { v in dragOffset = v.translation }
                            .onEnded { _ in
                                let rel = translateOffsetToRelative(
                                    translation: dragOffset,
                                    previewSize: UIScreen.main.bounds.size
                                )
                                position = rel
                                dragOffset = .zero
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { v in pinchScale = v }
                            .onEnded { v in fontScale *= v; pinchScale = 1.0 }
                    )

                    VStack {
                        // Top controls
                        HStack {
                            Button("Cancel") { onCancel() }
                                .font(AppFonts.rounded(16))
                                .padding(12)
                                .background(.clear) // no blur
                                .foregroundColor(.white)
                                .cornerRadius(12)

                            Spacer()

                            Button(action: { saveEditedClip() }) {
                                if isSaving {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 72, height: 36)
                                } else {
                                    Text("Save")
                                        .font(AppFonts.rounded(16))
                                }
                            }
                            .disabled(isSaving)
                            .padding(12)
                            .foregroundColor(.white)

                        }
                        .padding(.horizontal, 16)


                        Spacer()

                        // Bottom TextField
                        VStack(spacing: 8) {
                            TextField("Overlay text", text: $text)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 16)
                                .focused($textFieldFocused)

                            if showFontOptions {
                                HStack {
                                    Picker("", selection: $fontName) {
                                        ForEach(fonts, id: \.self) { f in Text(f).tag(f) }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)

                                    ColorPicker("", selection: $color)
                                        .labelsHidden()
                                        .frame(width: 44)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, textFieldFocused ? 300 : 24)

                        .cornerRadius(16)
                        .padding(.horizontal, 12)
                    }
                }
            }


            // MARK: - Trimming step (still full screen)
            if showingStep == .trim {
                VStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Trim").font(AppFonts.rounded(14)).foregroundColor(.white)
                        HStack {
                            Text(timeString(from: startTrim)).foregroundColor(.white)
                            
                            DoubleSlider(lowerValue: $startTrim, upperValue: $endTrim, range: 0...max(0.001, duration)) {
                                // Called when drag ends
                                seekPlayerToStart()
                            }
                            .frame(height: 40)
                            .padding(.horizontal)
                            
                            Text(timeString(from: endTrim)).foregroundColor(.white)
                        }
                        Text("Tip: pick the clip portion you want, then tap Next to add text.")
                            .font(AppFonts.rounded(12))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(16)
                    .padding(16)

                    Button("Next") {
                        ensureTrimBounds()
                        showingStep = .overlay
                        seekPlayerToStart()
                    }
                    .font(AppFonts.rounded(16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppColors.primary())
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding(.bottom, 32)
                }
            }
            
            // Dim background + activity indicator while saving
            if isSaving {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                ProgressView("Saving…")
                    .padding(16)
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(12)
            }
        }
        .onAppear { loadAsset() }
        .onDisappear { player?.pause() }
    }


    // MARK: - Helpers

    private func loadAsset() {
        let ids = [assetId]
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        guard let ph = assets.firstObject else { return }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: ph, options: options) { av, _, _ in
            DispatchQueue.main.async {
                guard let av = av else { return }
                self.avAsset = av
                let d = CMTimeGetSeconds(av.duration)
                self.duration = d
                self.startTrim = 0.0
                self.endTrim = d
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                self.text = "\(activityName) • \(formatter.string(from: activityStart))"
                self.color = .white

                setupPlayer()

            }
        }
    }

    private func setupPlayer() {
        guard let asset = avAsset else { return }
        let item = AVPlayerItem(asset: asset)
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }

        seekPlayerToStart()
        player?.play()
        player?.actionAtItemEnd = .none

        // remove old observer
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { currentTime in
            let currentSec = CMTimeGetSeconds(currentTime)
            if currentSec >= self.endTrim {
                // loop: seek back to startTrim
                self.player?.seek(to: CMTime(seconds: self.startTrim, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                self.player?.play()
            }
        }
    }

    private func seekPlayerToStart() {
        guard let player = player else { return }
        let t = CMTime(seconds: max(0, startTrim), preferredTimescale: 600)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func ensureTrimBounds() {
        if startTrim < 0 { startTrim = 0 }
        if endTrim > duration { endTrim = duration }
        if endTrim <= startTrim + 0.1 { endTrim = min(duration, startTrim + 0.1) }
    }

    private func timeString(from seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        let ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }

    private func translateOffsetToRelative(translation: CGSize, previewSize: CGSize) -> CGPoint {
        // Convert translation in points to relative 0..1
        let dx = translation.width / previewSize.width
        let dy = translation.height / previewSize.height
        var nx = position.x + dx
        var ny = position.y + dy
        nx = max(0.0, min(1.0, nx))
        ny = max(0.0, min(1.0, ny))
        return CGPoint(x: nx, y: ny)
    }

    // MARK: Export trimmed clip + overlay text as a new video saved to Photos
    // MARK: - Save / export
    private func saveEditedClip() {
        guard !isSaving else { return } // already running
        guard let avAsset = avAsset else { return }

        isSaving = true

        // Pause preview player while exporting for stability
        player?.pause()

        // Build composition just for trimmed range
        let startCM = CMTime(seconds: max(0, startTrim), preferredTimescale: 600)
        let durSec = max(0.1, endTrim - startTrim)
        let durationCM = CMTime(seconds: durSec, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCM, duration: durationCM)

        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            finishWithError("Unable to create composition video track.")
            return
        }
        guard let sourceVideoTrack = avAsset.tracks(withMediaType: .video).first else {
            finishWithError("Source video track not found.")
            return
        }
        do {
            try compVideoTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)
        } catch {
            finishWithError("Insert video error: \(error.localizedDescription)")
            return
        }

        // audio (optional)
        if let sourceAudio = avAsset.tracks(withMediaType: .audio).first,
           let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            do {
                try compAudio.insertTimeRange(timeRange, of: sourceAudio, at: .zero)
            } catch {
                // continue — audio optional
                print("insert audio error:", error)
            }
        }

        // prepare videoComposition + overlay (mirrors preview overlay)
        let naturalSize = sourceVideoTrack.naturalSize.applying(sourceVideoTrack.preferredTransform)
        let renderSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: durationCM)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
        let transform = sourceVideoTrack.preferredTransform
        layerInstruction.setTransform(transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // overlay layer
        let overlayLayer = CATextLayer()
        overlayLayer.string = text
        overlayLayer.alignmentMode = .center
        overlayLayer.isWrapped = true
        overlayLayer.foregroundColor = UIColor(color).cgColor
        overlayLayer.rasterizationScale = UIScreen.main.scale
        overlayLayer.contentsScale = UIScreen.main.scale

        let baseSize = min(renderSize.width, renderSize.height) * 0.08 * fontScale * pinchScale
        overlayLayer.font = UIFont(name: fontName, size: baseSize)
        overlayLayer.fontSize = baseSize
        overlayLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width * 0.9, height: baseSize * 2)

        let px = position.x * renderSize.width
        let py = position.y * renderSize.height
        overlayLayer.position = CGPoint(x: px, y: py)
        overlayLayer.masksToBounds = false

        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: renderSize)
        videoLayer.frame = parentLayer.frame
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        // Export session
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            finishWithError("Cannot create export session")
            return
        }
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mov
        let outUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        exportSession.outputURL = outUrl

        // Run export
        print("Starting export to:", outUrl.path)
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("Export completed — saving to Photos")
                    // Ensure we have permission to add to Photos
                    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                        if status == .authorized || status == .limited {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outUrl)
                            }, completionHandler: { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        // fetch newest saved asset id
                                        let fetchOptions = PHFetchOptions()
                                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                                        fetchOptions.fetchLimit = 1
                                        let fetch = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                                        let id = fetch.firstObject?.localIdentifier ?? assetId
                                        let meta = ClipMetadata(
                                            assetId: id,
                                            suggestedText: text,
                                            fontName: fontName,
                                            fontScale: fontScale,
                                            position: position,
                                            colorHex: color.toHex(),
                                            trimmedStart: startCM,
                                            trimmedDuration: durationCM
                                        )
                                        // Success: call onSaved on main thread
                                        onSaved(id, meta)
                                        isSaving = false
                                    } else {
                                        finishWithError("Failed to save to Photos: \(error?.localizedDescription ?? "unknown")")
                                    }
                                    // cleanup temp file
                                    try? FileManager.default.removeItem(at: outUrl)
                                }
                            })
                        } else {
                            finishWithError("Photos permission denied — cannot save video.")
                            try? FileManager.default.removeItem(at: outUrl)
                        }
                    }
                case .failed:
                    let err = exportSession.error?.localizedDescription ?? "unknown"
                    finishWithError("Export failed: \(err)")
                    try? FileManager.default.removeItem(at: outUrl)
                case .cancelled:
                    finishWithError("Export cancelled")
                    try? FileManager.default.removeItem(at: outUrl)
                default:
                    // handle other statuses
                    let err = exportSession.error?.localizedDescription ?? "status: \(exportSession.status.rawValue)"
                    finishWithError("Export ended with unexpected status: \(err)")
                    try? FileManager.default.removeItem(at: outUrl)
                }
            }
        }
        }

        private func finishWithError(_ message: String) {
            print(message)
            alertMessage = message
            showAlert = true
            isSaving = false
            // resume preview if available
            player?.play()
        }
}
