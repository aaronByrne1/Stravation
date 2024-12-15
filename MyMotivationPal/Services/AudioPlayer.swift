import AVFoundation

class AudioPlayer: NSObject {
    private var player: AVAudioPlayer?

    override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set category to playback so audio can play even in silent mode
            //print("[AudioPlayer] Setting audio session category to playback...")
            try audioSession.setCategory(.playback, mode: .default, options: [])
            
            //print("[AudioPlayer] Activating audio session...")
            try audioSession.setActive(true, options: [])
            //print("[AudioPlayer] Audio session activated successfully.")
        } catch {
            //print("[AudioPlayer] Audio Session Configuration Error: \(error.localizedDescription)")
        }
    }

    func playAudioData(_ data: Data) {
        //print("[AudioPlayer] Received audio data of size: \(data.count) bytes")
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("tts_audio.mp3") // Adjust extension if needed

            //print("[AudioPlayer] Writing audio data to: \(fileURL.path)")
            try data.write(to: fileURL)

            //print("[AudioPlayer] Initializing AVAudioPlayer with the audio file...")
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.prepareToPlay()
            
            //print("[AudioPlayer] Playing audio...")
            let didPlay = player?.play() ?? false
            if didPlay {
                //print("[AudioPlayer] Audio is now playing.")
            } else {
                //print("[AudioPlayer] Audio failed to start playing.")
            }
        } catch {
            //print("[AudioPlayer] Audio Playback Error: \(error.localizedDescription)")
        }
    }

    func stop() {
        //print("[AudioPlayer] Stopping playback...")
        player?.stop()
    }
}
