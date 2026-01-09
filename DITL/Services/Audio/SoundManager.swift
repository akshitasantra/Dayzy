import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    private init() {
        prepareSound()
    }

    private func prepareSound() {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "mp3") else {
            print("click.mp3 not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            print("Audio error:", error)
        }
    }

    func playClick() {
        player?.currentTime = 0
        player?.play()
    }
}
