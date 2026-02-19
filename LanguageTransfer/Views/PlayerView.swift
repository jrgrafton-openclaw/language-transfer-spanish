import SwiftUI
import AVFoundation

// MARK: - PlayerView

struct PlayerView: View {
    let lesson: Lesson

    @EnvironmentObject var store: LessonStore
    @EnvironmentObject var player: AudioPlayerService
    @Environment(\.dismiss) var dismiss

    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var showSpeedPicker = false
    @State private var hasLoadedLesson = false

    private let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var currentLesson: Lesson {
        store.lessons.first(where: { $0.id == lesson.id }) ?? lesson
    }

    var displayTime: TimeInterval {
        isScrubbing ? scrubTime : player.currentTime
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle + dismiss
                headerBar

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Artwork
                        artworkView
                            .padding(.top, Spacing.xl)

                        // Lesson title
                        titleSection

                        // Scrub bar
                        scrubBar

                        // Main controls
                        mainControls

                        // Speed picker
                        speedPicker

                        // Download button
                        downloadButton

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
        }
        .onAppear { loadLesson() }
        .onChange(of: lesson.id) { _, _ in loadLesson() }
        .onChange(of: player.currentTime) { _, time in
            if !isScrubbing {
                // Periodically save position
                store.savePosition(time, for: currentLesson.id)
                // Mark completed at 90%
                if player.duration > 0 && time / player.duration > 0.9 && !currentLesson.isCompleted {
                    store.markCompleted(currentLesson.id)
                }
                // Update now playing
                player.updateNowPlaying(lesson: currentLesson)
            }
        }
    }

    // MARK: - Load

    private func loadLesson() {
        guard !hasLoadedLesson || player.currentTime == 0 else { return }
        hasLoadedLesson = true
        let savedPos = store.loadPosition(for: lesson.id)
        player.load(lesson: currentLesson, startAt: savedPos)
        player.play()
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#2a3060"),
                Color(hex: "#1a1f3c"),
                ThemeColor.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Language Transfer")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .kerning(1)

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var artworkView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#7186d0"), Color(hex: "#516198")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: Color(hex: "#7186d0").opacity(0.4), radius: 24, y: 8)

            VStack(spacing: Spacing.md) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Complete Spanish")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Language Transfer")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var titleSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(currentLesson.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Lesson \(currentLesson.lessonNumber) of \(store.lessons.count)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var scrubBar: some View {
        VStack(spacing: Spacing.sm) {
            // Waveform-style progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Buffer track
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 4)

                    // Buffer progress
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: geo.size.width * player.bufferProgress, height: 4)

                    // Playback progress
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * progressFraction, height: 4)

                    // Scrub thumb
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .offset(x: geo.size.width * progressFraction - 8)
                        .animation(.none, value: progressFraction)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let fraction = max(0, min(1, value.location.x / geo.size.width))
                            scrubTime = fraction * player.duration
                        }
                        .onEnded { _ in
                            player.seek(to: scrubTime)
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 16)

            HStack {
                Text(formatTime(displayTime))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(player.duration))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var progressFraction: Double {
        guard player.duration > 0 else { return 0 }
        return displayTime / player.duration
    }

    private var mainControls: some View {
        VStack(spacing: Spacing.xl) {
            // Previous / Skip-back / Play / Skip-forward / Next
            HStack(spacing: 0) {
                // Previous lesson
                Button {
                    if let prev = store.previousLesson(before: currentLesson) {
                        navigateTo(prev)
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(store.previousLesson(before: currentLesson) != nil
                            ? .white.opacity(0.85)
                            : .white.opacity(0.25))
                }
                .disabled(store.previousLesson(before: currentLesson) == nil)
                .frame(maxWidth: .infinity)

                // Skip back 15s
                Button {
                    player.skip(by: -15)
                } label: {
                    ZStack {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity)

                // Play/Pause (large)
                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                        if player.isLoading {
                            ProgressView()
                                .tint(Color(hex: "#516198"))
                        } else {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color(hex: "#516198"))
                                .offset(x: player.isPlaying ? 0 : 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(player.isPlaying ? 1.0 : 0.95)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: player.isPlaying)

                // Skip forward 30s
                Button {
                    player.skip(by: 30)
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)

                // Next lesson
                Button {
                    if let next = store.nextLesson(after: currentLesson) {
                        navigateTo(next)
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(store.nextLesson(after: currentLesson) != nil
                            ? .white.opacity(0.85)
                            : .white.opacity(0.25))
                }
                .disabled(store.nextLesson(after: currentLesson) == nil)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Spacing.sm)
        }
    }

    private var speedPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(speeds, id: \.self) { speed in
                Button {
                    withAnimation(.easeInOut(duration: Motion.fast)) {
                        player.setRate(speed)
                    }
                } label: {
                    Text(speedLabel(speed))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            player.playbackRate == speed
                                ? .white
                                : .white.opacity(0.12)
                        )
                        .foregroundStyle(
                            player.playbackRate == speed
                                ? Color(hex: "#516198")
                                : .white.opacity(0.7)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var downloadButton: some View {
        Button {
            handleDownload()
        } label: {
            HStack(spacing: Spacing.sm) {
                downloadIcon
                Text(downloadLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var downloadIcon: some View {
        switch currentLesson.downloadState {
        case .notDownloaded, .failed:
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 18))
        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 18, height: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
            }
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.green)
        }
    }

    private var downloadLabel: String {
        switch currentLesson.downloadState {
        case .notDownloaded: return "Download"
        case .downloading(let p): return String(format: "Downloading %.0f%%", p * 100)
        case .downloaded: return "Downloaded"
        case .failed: return "Retry Download"
        }
    }

    // MARK: - Helpers

    private func navigateTo(_ lesson: Lesson) {
        player.stop()
        store.currentLesson = lesson
        hasLoadedLesson = false
        loadLesson()
    }

    private func handleDownload() {
        switch currentLesson.downloadState {
        case .downloaded:
            // Delete
            DownloadManager.shared.deleteLocalFile(for: currentLesson.id)
            store.updateDownloadState(.notDownloaded, for: currentLesson.id)
        case .downloading:
            DownloadManager.shared.cancelDownload(for: currentLesson.id)
            store.updateDownloadState(.notDownloaded, for: currentLesson.id)
        case .notDownloaded, .failed:
            store.updateDownloadState(.downloading(progress: 0), for: currentLesson.id)
            DownloadManager.shared.download(
                lesson: currentLesson,
                progress: { [weak store] p in
                    store?.updateDownloadState(.downloading(progress: p), for: currentLesson.id)
                },
                completion: { [weak store] result in
                    switch result {
                    case .success:
                        store?.updateDownloadState(.downloaded, for: currentLesson.id)
                    case .failure:
                        store?.updateDownloadState(.failed, for: currentLesson.id)
                    }
                }
            )
        }
    }

    private func speedLabel(_ speed: Float) -> String {
        if speed == 1.0 { return "1×" }
        if speed == 0.5 { return "0.5×" }
        if speed == 0.75 { return "0.75×" }
        if speed == 1.25 { return "1.25×" }
        if speed == 1.5 { return "1.5×" }
        if speed == 2.0 { return "2×" }
        return "\(speed)×"
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    PlayerView(lesson: Lesson.from(SpanishLessons.all[0]))
        .environmentObject(LessonStore())
        .environmentObject(AudioPlayerService())
}
