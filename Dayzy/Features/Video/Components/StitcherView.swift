import SwiftUI
import AVFoundation
import Photos

struct StitcherView: View {
    let clips: [ClipMetadata]   // in-order clips for the day
    let onExported: (String) -> Void   // new asset id of exported stitched video
    let onCancel: () -> Void

    @State private var player: AVPlayer? = nil
    @State private var isExporting = false

    var body: some View {
        VStack {
            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Text("Preview Day")
                Spacer()
                Button(action: { exportStitched() }) {
                    if isExporting { ProgressView() } else { Text("Export") }
                }
            }
            .padding(.horizontal)

            if let player = player {
                VideoPlayerView(player: player)
                    .frame(height: 360)
                    .cornerRadius(AppLayout.cornerRadius)
            } else {
                Rectangle().fill(Color.black).frame(height: 360)
            }

            Spacer()
        }
        .onAppear {
            buildPreviewComposition()
        }
        .padding()
    }

    // Builds a composition that stitches trimmed ranges of clips together and overlays each clip's text at the appropriate times.
    private func buildPreviewComposition() {
        var assets: [AVAsset] = []
        let group = DispatchGroup()
        for clip in clips {
            group.enter()
            let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [clip.assetId], options: nil)
            guard let ph = fetch.firstObject else { group.leave(); continue }
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: ph, options: options) { av, _, _ in
                if let av = av { assets.append(av) }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // compose them
            let composition = AVMutableComposition()
            var currentTime = CMTime.zero
            var videoTrack: AVMutableCompositionTrack? = nil
            var audioTrack: AVMutableCompositionTrack? = nil
            var trackNaturalSize = CGSize(width: 1920, height: 1080)

            for (i, av) in assets.enumerated() {
                guard let vtr = av.tracks(withMediaType: .video).first else { continue }
                let metadata = clips[i]
                let range = CMTimeRange(start: metadata.trimmedStart, duration: metadata.trimmedDuration)

                if videoTrack == nil {
                    videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                if let vt = videoTrack {
                    do {
                        try vt.insertTimeRange(range, of: vtr, at: currentTime)
                        vt.preferredTransform = vtr.preferredTransform
                        trackNaturalSize = vtr.naturalSize.applying(vtr.preferredTransform)
                    } catch {
                        print("insert error", error)
                    }
                }

                if let atr = av.tracks(withMediaType: .audio).first {
                    if audioTrack == nil {
                        audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    }
                    if let at = audioTrack {
                        do {
                            try at.insertTimeRange(range, of: atr, at: currentTime)
                        } catch {
                            print("audio insert error", error)
                        }
                    }
                }

                currentTime = currentTime + metadata.trimmedDuration
            }

            // build player item with overlay via videoComposition + CoreAnimation
            guard let vTrack = videoTrack else { return }

            let renderSize = CGSize(width: abs(trackNaturalSize.width), height: abs(trackNaturalSize.height))
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
            // no transforms here — assume consistent
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            // Build parent layer and add per-clip text layers timed to clip ranges
            let parent = CALayer()
            let videoLayer = CALayer()
            parent.frame = CGRect(origin: .zero, size: renderSize)
            videoLayer.frame = parent.frame
            parent.addSublayer(videoLayer)

            // compute each clip's start position in timeline
            var compTime = CMTime.zero
            for clip in clips {
                let txtLayer = CATextLayer()
                txtLayer.string = clip.suggestedText
                txtLayer.alignmentMode = .center
                txtLayer.foregroundColor = UIColor(Color.fromHex(clip.colorHex)).cgColor
                txtLayer.font = UIFont(name: clip.fontName, size: (min(renderSize.width, renderSize.height) * 0.08 * clip.fontScale))
                txtLayer.fontSize = (min(renderSize.width, renderSize.height) * 0.08 * clip.fontScale)
                txtLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width * 0.9, height: 80)
                let px = clip.position.x * renderSize.width
                let py = clip.position.y * renderSize.height
                txtLayer.position = CGPoint(x: px, y: py)
                txtLayer.isWrapped = true
                txtLayer.masksToBounds = false

                // add timing via beginTime and duration (use CAMediaTiming)
                let begin = CMTimeGetSeconds(compTime)
                let dur = CMTimeGetSeconds(clip.trimmedDuration)
                // Because animation time is relative to AVCoreAnimationBeginTimeAtZero, we set beginTime on an opacity animation.
                let anim = CABasicAnimation(keyPath: "opacity")
                anim.fromValue = 1.0
                anim.toValue = 1.0
                anim.duration = dur
                anim.beginTime = AVCoreAnimationBeginTimeAtZero + begin
                anim.fillMode = .forwards
                anim.isRemovedOnCompletion = false
                txtLayer.add(anim, forKey: "stay")
                parent.addSublayer(txtLayer)

                compTime = compTime + clip.trimmedDuration
            }

            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

            let item = AVPlayerItem(asset: composition)
            item.videoComposition = videoComposition
            let avp = AVPlayer(playerItem: item)
            self.player = avp
            avp.play()
        }
    }

    // Export full stitched video with the same overlays written into file and saved to Photos.
    private func exportStitched() {
        guard !isExporting else { return }
        isExporting = true

        // Build composition same as preview but export to file (similar steps to preview creation)
        // Implementation uses the same logic as buildPreviewComposition but writes to file and saves to Photos.
        // For brevity: reuse buildPreviewComposition but export using AVAssetExportSession.

        // ---- simplified: create composition by calling the internal steps again synchronously ----
        // (For readability the code is similar to preview composition construction.)
        DispatchQueue.global(qos: .userInitiated).async {
            // fetch AVAssets
            var assets: [AVAsset] = []
            let group = DispatchGroup()
            for clip in clips {
                group.enter()
                let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [clip.assetId], options: nil)
                guard let ph = fetch.firstObject else { group.leave(); continue }
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestAVAsset(forVideo: ph, options: options) { av, _, _ in
                    if let av = av { assets.append(av) }
                    group.leave()
                }
            }
            group.wait()

            // compose...
            let composition = AVMutableComposition()
            var currentTime = CMTime.zero
            var videoTrack: AVMutableCompositionTrack? = nil
            var trackNaturalSize = CGSize(width: 1920, height: 1080)

            for (i, av) in assets.enumerated() {
                guard let vtr = av.tracks(withMediaType: .video).first else { continue }
                let metadata = clips[i]
                let range = CMTimeRange(start: metadata.trimmedStart, duration: metadata.trimmedDuration)
                if videoTrack == nil {
                    videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                if let vt = videoTrack {
                    do {
                        try vt.insertTimeRange(range, of: vtr, at: currentTime)
                        vt.preferredTransform = vtr.preferredTransform
                        trackNaturalSize = vtr.naturalSize.applying(vtr.preferredTransform)
                    } catch { print(error) }
                }
                if let atr = av.tracks(withMediaType: .audio).first,
                   let at = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    do {
                        try at.insertTimeRange(range, of: atr, at: currentTime)
                    } catch { print(error) }
                }
                currentTime = currentTime + metadata.trimmedDuration
            }

            guard let vTrack = videoTrack else {
                DispatchQueue.main.async { isExporting = false }
                return
            }

            let renderSize = CGSize(width: abs(trackNaturalSize.width), height: abs(trackNaturalSize.height))
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            // build parent layer and text overlays timed by clips
            let parent = CALayer()
            let videoLayer = CALayer()
            parent.frame = CGRect(origin: .zero, size: renderSize)
            videoLayer.frame = parent.frame
            parent.addSublayer(videoLayer)

            var compT = CMTime.zero
            for clip in clips {
                let txtLayer = CATextLayer()
                txtLayer.string = clip.suggestedText
                txtLayer.alignmentMode = .center
                txtLayer.foregroundColor = UIColor(Color.fromHex(clip.colorHex)).cgColor
                txtLayer.font = UIFont(name: clip.fontName, size: (min(renderSize.width, renderSize.height) * 0.08 * clip.fontScale))
                txtLayer.fontSize = (min(renderSize.width, renderSize.height) * 0.08 * clip.fontScale)
                txtLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width * 0.9, height: 100)
                txtLayer.position = CGPoint(x: clip.position.x * renderSize.width, y: clip.position.y * renderSize.height)
                txtLayer.isWrapped = true
                // add timing via basic animation
                let startSec = CMTimeGetSeconds(compT)
                let durSec = CMTimeGetSeconds(clip.trimmedDuration)
                let anim = CABasicAnimation(keyPath: "opacity")
                anim.fromValue = 1.0
                anim.toValue = 1.0
                anim.duration = durSec
                anim.beginTime = AVCoreAnimationBeginTimeAtZero + startSec
                anim.fillMode = .forwards
                anim.isRemovedOnCompletion = false
                txtLayer.add(anim, forKey: "stay")
                parent.addSublayer(txtLayer)
                compT = compT + clip.trimmedDuration
            }

            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

            // export
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                DispatchQueue.main.async { isExporting = false }
                return
            }
            exportSession.videoComposition = videoComposition
            exportSession.outputFileType = .mov
            let outUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            exportSession.outputURL = outUrl

            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    isExporting = false
                }
                if exportSession.status == .completed {
                    // save to photos
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outUrl)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                // fetch created asset id
                                let fetch = PHAsset.fetchAssets(with: .video, options: {
                                    let o = PHFetchOptions()
                                    o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                                    o.fetchLimit = 1
                                    return o
                                }())
                                if let newPH = fetch.firstObject {
                                    onExported(newPH.localIdentifier)
                                } else {
                                    onExported("") // fallback
                                }
                            } else {
                                print("Save error:", error as Any)
                            }
                        }
                    }
                } else {
                    print("export failed", exportSession.status, exportSession.error as Any)
                }
                try? FileManager.default.removeItem(at: outUrl)
            }
        }
    }
}
