import Foundation
import AVFoundation
import Combine

class AudioService: ObservableObject {
    static let shared = AudioService()
    private var player: AVPlayer?
    
    @Published var isPlaying = false
    
    func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
        
        // Observe when playback finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
    }
    
    @objc private func playerDidFinishPlaying(note: NSNotification) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
