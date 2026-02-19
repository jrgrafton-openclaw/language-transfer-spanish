import SwiftUI

// MARK: - LessonListView

struct LessonListView: View {
    @EnvironmentObject var store: LessonStore
    @EnvironmentObject var player: AudioPlayerService
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Continue banner
                        if let inProgress = store.lessonInProgress {
                            ContinueBanner(lesson: inProgress) {
                                store.openLesson(inProgress)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                        }

                        // Header
                        CourseHeader()
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                        // Lesson rows
                        VStack(spacing: 0) {
                            ForEach(store.lessons) { lesson in
                                LessonRow(lesson: lesson) {
                                    store.openLesson(lesson)
                                }
                                if lesson.lessonNumber < store.lessons.count {
                                    Divider()
                                        .padding(.leading, Spacing.lg + 44 + Spacing.md)
                                }
                            }
                        }
                        .background(ThemeColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .strokeBorder(ThemeColor.stroke, lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Spanish")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $store.isPlayerPresented) {
                if let lesson = store.currentLesson {
                    PlayerView(lesson: lesson)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Course Header

private struct CourseHeader: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#7186d0"), Color(hex: "#516198")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Complete Spanish")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(ThemeColor.textPrimary)
                Text("90 lessons · ~15 hours · Free forever")
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(ThemeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(ThemeColor.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Continue Banner

private struct ContinueBanner: View {
    let lesson: Lesson
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(ThemeColor.primaryTint)
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeColor.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(ThemeColor.primary)
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ThemeColor.textPrimary)
                }

                Spacer()

                // Progress
                ZStack {
                    Circle()
                        .stroke(ThemeColor.stroke, lineWidth: 3)
                        .frame(width: 32, height: 32)
                    Circle()
                        .trim(from: 0, to: lesson.progressFraction)
                        .stroke(ThemeColor.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(Spacing.md)
            .background(ThemeColor.primaryTint)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(ThemeColor.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LessonRow

struct LessonRow: View {
    let lesson: Lesson
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Number / status indicator
                ZStack {
                    Circle()
                        .fill(circleBackground)
                        .frame(width: 44, height: 44)

                    if lesson.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(lesson.lessonNumber)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(numberColor)
                    }
                }

                // Title + duration
                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ThemeColor.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        Text(lesson.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)

                        if lesson.savedPosition > 5 && !lesson.isCompleted {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(ThemeColor.textTertiary)
                            Text(timeFormatted(lesson.savedPosition) + " played")
                                .font(.caption)
                                .foregroundStyle(ThemeColor.primary)
                        }
                    }

                    // Progress bar
                    if lesson.savedPosition > 5 && !lesson.isCompleted {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(ThemeColor.stroke)
                                    .frame(height: 3)
                                Capsule()
                                    .fill(ThemeColor.primary)
                                    .frame(width: geo.size.width * lesson.progressFraction, height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Download indicator
                downloadIndicator

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textTertiary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var circleBackground: Color {
        if lesson.isCompleted { return ThemeColor.primary }
        if lesson.savedPosition > 5 { return ThemeColor.primaryTint }
        return ThemeColor.surfaceAlt
    }

    private var numberColor: Color {
        lesson.savedPosition > 5 ? ThemeColor.primary : ThemeColor.textSecondary
    }

    @ViewBuilder
    private var downloadIndicator: some View {
        switch lesson.downloadState {
        case .downloaded:
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(ThemeColor.success)
        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(ThemeColor.stroke, lineWidth: 2)
                    .frame(width: 20, height: 20)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ThemeColor.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
        case .notDownloaded, .failed:
            EmptyView()
        }
    }

    private func timeFormatted(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LessonListView()
        .environmentObject(LessonStore())
        .environmentObject(AudioPlayerService())
}
