import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var player: AudioPlayerService
    @EnvironmentObject var store: LessonStore
    @Environment(\.dismiss) var dismiss

    @AppStorage("default_playback_speed") private var defaultSpeed: Double = 1.0
    @State private var selectedSleepTimer: Int = 0
    @State private var sleepTimerRemaining: String = ""
    private let sleepOptions = [0, 15, 30, 45, 60]
    private let speeds: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                List {
                    // Playback Speed
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Default Speed")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(speeds, id: \.self) { speed in
                                        Button {
                                            defaultSpeed = speed
                                        } label: {
                                            Text(speedLabel(speed))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, Spacing.md)
                                                .padding(.vertical, Spacing.sm)
                                                .background(
                                                    defaultSpeed == speed
                                                        ? ThemeColor.primary
                                                        : ThemeColor.surfaceAlt
                                                )
                                                .foregroundStyle(
                                                    defaultSpeed == speed
                                                        ? Color.white
                                                        : ThemeColor.textPrimary
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                        .listRowBackground(ThemeColor.surface)
                    } header: {
                        Text("Playback")
                    }

                    // Sleep Timer
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Sleep Timer")
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeColor.textSecondary)
                                Spacer()
                                if !sleepTimerRemaining.isEmpty {
                                    Text(sleepTimerRemaining)
                                        .font(.caption)
                                        .foregroundStyle(ThemeColor.primary)
                                }
                            }

                            HStack(spacing: Spacing.sm) {
                                ForEach(sleepOptions, id: \.self) { minutes in
                                    Button {
                                        selectedSleepTimer = minutes
                                        player.setSleepTimer(minutes: minutes)
                                    } label: {
                                        Text(minutes == 0 ? "Off" : "\(minutes)m")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, Spacing.md)
                                            .padding(.vertical, Spacing.sm)
                                            .background(
                                                selectedSleepTimer == minutes
                                                    ? ThemeColor.primary
                                                    : ThemeColor.surfaceAlt
                                            )
                                            .foregroundStyle(
                                                selectedSleepTimer == minutes
                                                    ? Color.white
                                                    : ThemeColor.textPrimary
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                        .listRowBackground(ThemeColor.surface)
                    } header: {
                        Text("Sleep Timer")
                    }

                    // Progress
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lessons Completed")
                                    .foregroundStyle(ThemeColor.textPrimary)
                                Text("\(completedCount) of 90")
                                    .font(.caption)
                                    .foregroundStyle(ThemeColor.textSecondary)
                            }
                            Spacer()
                            // Mini progress ring
                            ZStack {
                                Circle()
                                    .stroke(ThemeColor.stroke, lineWidth: 4)
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .trim(from: 0, to: Double(completedCount) / 90.0)
                                    .stroke(ThemeColor.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(Double(completedCount) / 90.0 * 100))%")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(ThemeColor.textPrimary)
                            }
                        }
                        .listRowBackground(ThemeColor.surface)
                    } header: {
                        Text("Progress")
                    }

                    // About
                    Section {
                        HStack {
                            Text("Course")
                            Spacer()
                            Text("Complete Spanish")
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                        .listRowBackground(ThemeColor.surface)

                        HStack {
                            Text("Lessons")
                            Spacer()
                            Text("90")
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                        .listRowBackground(ThemeColor.surface)

                        HStack {
                            Text("Total Duration")
                            Spacer()
                            Text("~15 hours")
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                        .listRowBackground(ThemeColor.surface)

                        Link(destination: URL(string: "https://www.languagetransfer.org")!) {
                            HStack {
                                Text("Language Transfer Website")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                        .listRowBackground(ThemeColor.surface)
                    } header: {
                        Text("About")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onReceive(timer) { _ in
                updateSleepTimerDisplay()
            }
        }
    }

    private var completedCount: Int {
        store.lessons.filter { $0.isCompleted }.count
    }

    private func updateSleepTimerDisplay() {
        if let remaining = player.sleepTimerRemaining {
            let m = Int(remaining) / 60
            let s = Int(remaining) % 60
            sleepTimerRemaining = String(format: "%d:%02d", m, s)
        } else {
            sleepTimerRemaining = ""
            selectedSleepTimer = 0
        }
    }

    private func speedLabel(_ speed: Double) -> String {
        if speed == 1.0 { return "1×" }
        return "\(speed)×"
    }
}

#Preview {
    SettingsView()
        .environmentObject(AudioPlayerService())
        .environmentObject(LessonStore())
}
