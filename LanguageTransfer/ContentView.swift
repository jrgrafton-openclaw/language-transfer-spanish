import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            ThemeColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {

                    // MARK: - Hero
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(ThemeColor.primaryTint)
                                .frame(width: 120, height: 120)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(ThemeColor.primary)
                        }
                        .padding(.top, Spacing.xxl)

                        Text("Language Transfer")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(ThemeColor.textSecondary)

                        Text("Spanish")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(ThemeColor.textPrimary)

                        Text("Learn naturally through conversation")
                            .font(.body)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }

                    // MARK: - Stats strip
                    HStack(spacing: 0) {
                        StatPill(value: "40", label: "lessons")
                        Divider()
                            .frame(height: 32)
                            .overlay(ThemeColor.stroke)
                        StatPill(value: "Free", label: "forever")
                        Divider()
                            .frame(height: 32)
                            .overlay(ThemeColor.stroke)
                        StatPill(value: "~15h", label: "total")
                    }
                    .padding(.vertical, Spacing.md)
                    .background(ThemeColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .strokeBorder(ThemeColor.stroke, lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)

                    // MARK: - Feature cards
                    VStack(spacing: Spacing.md) {
                        FeatureCard(
                            icon: "headphones",
                            title: "Audio-First",
                            description: "Learn through listening, the natural way"
                        )
                        FeatureCard(
                            icon: "brain.head.profile",
                            title: "No Memorization",
                            description: "Build intuition, not vocabulary lists"
                        )
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Real Progress",
                            description: "From zero to conversational Spanish"
                        )
                    }
                    .padding(.horizontal, Spacing.lg)

                    // MARK: - CTA
                    VStack(spacing: Spacing.sm) {
                        Button {
                            // TODO: Start first lesson
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "play.fill")
                                Text("Start Learning")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(ThemeColor.primary)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        }

                        Text("Free · No sign-up required")
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textTertiary)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm - 4, style: .continuous)
                    .fill(ThemeColor.accentTint)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ThemeColor.accent)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(ThemeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .strokeBorder(ThemeColor.stroke, lineWidth: 1)
        )
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(ThemeColor.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    ContentView()
}
