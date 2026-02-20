import SwiftUI
import AVFoundation

// MARK: - Robust VideoPlayerView (UIViewRepresentable that manages AVPlayerLayer properly)
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setPlayer(player)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }

    // small container UIView which holds the AVPlayerLayer and updates its frame reliably
    class PlayerUIView: UIView {
        private var playerLayer: AVPlayerLayer?

        override class var layerClass: AnyClass { AVPlayerLayer.self }

        override init(frame: CGRect) {
            super.init(frame: frame)
            // nothing else
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        func setPlayer(_ player: AVPlayer) {
            if let layer = self.layer as? AVPlayerLayer {
                layer.player = player
                layer.videoGravity = .resizeAspectFill
                self.playerLayer = layer
            } else {
                // fallback: create dedicated layer
                if playerLayer == nil {
                    let l = AVPlayerLayer(player: player)
                    l.videoGravity = .resizeAspectFill
                    layer.addSublayer(l)
                    playerLayer = l
                }
                playerLayer?.player = player
            }
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // ensure player layer fills view
            if let pl = playerLayer {
                pl.frame = bounds
            } else if let layer = self.layer as? AVPlayerLayer {
                layer.frame = bounds
            }
        }
    }
}
