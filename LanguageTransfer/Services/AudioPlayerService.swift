import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - AudioPlayerService

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var isLoading: Bool = false
    @Published var bufferProgress: Double = 0

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?

    private var sleepTimer: Timer?
    private(set) var sleepTimerEndTime: Date? = nil

    // Callback for when a track finishes
    var onTrackFinished: (() -> Void)?
    var onPositionUpdate: ((TimeInterval) -> Void)?

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }

    deinit {
        // Cleanup done in teardown() when explicitly called
        // Cannot call MainActor-isolated teardown() from deinit
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Load & Play

    func load(lesson: Lesson, startAt position: TimeInterval = 0) {
        stop()
        isLoading = true
        currentTime = position
        duration = lesson.duration

        let url = lesson.localFileURL ?? lesson.lqURL
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let item = AVPlayerItem(asset: asset)
        playerItem = item

        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = true
        player = p

        setupObservers(for: item, player: p)

        if position > 0 {
            let seekTime = CMTime(seconds: position, preferredTimescale: 1000)
            p.seek(to: seekTime) { [weak self] _ in
                Task { @MainActor in
                    self?.applyRate()
                    self?.isLoading = false
                }
            }
        }

        updateNowPlaying(lesson: lesson)
    }

    func play() {
        applyRate()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        pause()
        removeObservers()
        player = nil
        playerItem = nil
        isLoading = false
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: TimeInterval) {
        let clamped = max(0, min(time, duration))
        let cmTime = CMTime(seconds: clamped, preferredTimescale: 1000)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = clamped
            }
        }
    }

    func skip(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying { applyRate() }
    }

    private func applyRate() {
        player?.rate = playbackRate
        isPlaying = (player?.rate ?? 0) > 0
    }

    // MARK: - Observers

    private func setupObservers(for item: AVPlayerItem, player: AVPlayer) {
        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let secs = CMTimeGetSeconds(time)
                if secs.isFinite {
                    self.currentTime = secs
                    self.onPositionUpdate?(secs)
                }
            }
        }

        // Status observer
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isLoading = false
                    let d = CMTimeGetSeconds(item.duration)
                    if d.isFinite && d > 0 {
                        self.duration = d
                    }
                    if self.isPlaying {
                        self.applyRate()
                    }
                case .failed:
                    self.isLoading = false
                    print("Player item failed: \(item.error?.localizedDescription ?? "unknown")")
                default:
                    break
                }
            }
        }

        // Buffer observer
        bufferObserver = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let range = item.loadedTimeRanges.first?.timeRangeValue {
                    let buffered = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
                    let dur = self.duration
                    if dur > 0 {
                        self.bufferProgress = buffered / dur
                    }
                }
            }
        }

        // End of track
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    @objc private func playerDidFinish() {
        Task { @MainActor in
            isPlaying = false
            onTrackFinished?()
        }
    }

    private func removeObservers() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        bufferObserver?.invalidate()
        bufferObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    func teardown() {
        removeObservers()
        player?.pause()
        player = nil
        playerItem = nil
        sleepTimer?.invalidate()
    }

    // MARK: - Now Playing / Remote Commands

    private func setupRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        cc.skipBackwardCommand.preferredIntervals = [15]
        cc.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skip(by: -15) }
            return .success
        }
        cc.skipForwardCommand.preferredIntervals = [30]
        cc.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skip(by: 30) }
            return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent {
                Task { @MainActor in self?.seek(to: e.positionTime) }
            }
            return .success
        }
    }

    func updateNowPlaying(lesson: Lesson) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: lesson.title,
            MPMediaItemPropertyArtist: "Language Transfer",
            MPMediaItemPropertyAlbumTitle: "Complete Spanish",
            MPMediaItemPropertyPlaybackDuration: lesson.duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        // Add artwork
        if let image = UIImage(named: "AppIcon") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Sleep Timer

    func setSleepTimer(minutes: Int) {
        sleepTimer?.invalidate()
        if minutes <= 0 {
            sleepTimerEndTime = nil
            return
        }
        let endTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepTimerEndTime = endTime
        sleepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.pause()
                self?.sleepTimerEndTime = nil
            }
        }
    }

    var sleepTimerRemaining: TimeInterval? {
        guard let end = sleepTimerEndTime else { return nil }
        return max(0, end.timeIntervalSinceNow)
    }
}
