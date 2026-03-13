import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var engine: GameEngine

    // MARK: - Colors

    private let navyBg = Color(hex: "#0f172a")
    private let cardBg = Color(hex: "#1e293b")
    private let gold = Color(hex: "#fbbf24")
    private let foxOrange = Color(hex: "#f97316")
    private let subtleText = Color(hex: "#94a3b8")
    private let dimText = Color(hex: "#64748b")

    var body: some View {
        let stage = GameEngine.evolutionStage(for: engine.state.level)
        let xpProgress = GameEngine.xpProgress(totalXP: engine.state.xp)
        let stageColor = Color(hex: stage.color)
        let streakMult = GameEngine.streakMultiplier(engine.state.streakDays)

        ScrollView {
            VStack(spacing: 20) {
                foxSection(stage: stage, stageColor: stageColor)
                levelSection(
                    level: engine.state.level,
                    xpProgress: xpProgress,
                    streakMult: streakMult
                )
                statGrid
                evolutionProgressSection(stage: stage, stageColor: stageColor)
                totalXPSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(navyBg.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Fox Section

    @ViewBuilder
    private func foxSection(stage: EvolutionStage, stageColor: Color) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                FoxView(stage: stage, size: 180, isAnimating: true)
                    .frame(height: 190)

                Text(stage.name)
                    .font(.title2.bold())
                    .foregroundStyle(stageColor)

                Text("\(stage.tails)-Tail Spirit Fox")
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Level & XP Section

    @ViewBuilder
    private func levelSection(
        level: Int,
        xpProgress: (current: Int, needed: Int, percentage: Double),
        streakMult: Double
    ) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LEVEL")
                            .font(.caption.bold())
                            .foregroundStyle(subtleText)
                            .tracking(1.2)

                        Text("\(level)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Streak multiplier badge
                    if streakMult > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(foxOrange)
                            Text("\(streakMult, specifier: "%.1f")x")
                                .font(.headline.bold())
                                .foregroundStyle(foxOrange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(foxOrange.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(foxOrange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }

                // XP Progress bar
                VStack(spacing: 6) {
                    XPBarView(
                        current: xpProgress.current,
                        total: xpProgress.needed,
                        barColor: gold
                    )
                    .frame(height: 14)

                    HStack {
                        Text("\(xpProgress.current) XP")
                            .font(.caption.bold())
                            .foregroundStyle(gold)

                        Spacer()

                        Text("\(xpProgress.needed) XP needed")
                            .font(.caption)
                            .foregroundStyle(subtleText)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        let questsDone = engine.state.questCompleted.values.filter { $0 }.count
        let focusHours = Double(engine.state.totalFocusMinutes) / 60.0

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            StatCard(
                icon: "flame.fill",
                iconColor: foxOrange,
                title: "Streak",
                value: "\(engine.state.streakDays)",
                unit: "days"
            )

            StatCard(
                icon: "clock.fill",
                iconColor: Color(hex: "#38bdf8"),
                title: "Focus Time",
                value: String(format: "%.1f", focusHours),
                unit: "hours"
            )

            StatCard(
                icon: "checkmark.seal.fill",
                iconColor: Color(hex: "#4ade80"),
                title: "Quests Done",
                value: "\(questsDone)",
                unit: "completed"
            )

            StatCard(
                icon: "shield.fill",
                iconColor: Color(hex: "#7c3aed"),
                title: "Boss Defeats",
                value: "\(engine.state.bossDefeats)",
                unit: "defeated"
            )
        }
    }

    // MARK: - Evolution Progress

    @ViewBuilder
    private func evolutionProgressSection(stage: EvolutionStage, stageColor: Color) -> some View {
        let nextStage = evolutionStages.first { $0.minLevel > engine.state.level }

        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(stageColor)
                    Text("Evolution Progress")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }

                if let next = nextStage {
                    let levelsRemaining = next.minLevel - engine.state.level
                    let totalLevels = next.minLevel - stage.minLevel
                    let levelsInStage = engine.state.level - stage.minLevel

                    XPBarView(
                        current: levelsInStage,
                        total: totalLevels,
                        barColor: stageColor
                    )
                    .frame(height: 10)

                    HStack {
                        Text(stage.name)
                            .font(.caption.bold())
                            .foregroundStyle(stageColor)

                        Spacer()

                        Text("\(levelsRemaining) levels to \(next.name)")
                            .font(.caption)
                            .foregroundStyle(subtleText)
                    }
                } else {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(gold)
                        Text("Maximum Evolution Reached!")
                            .font(.subheadline.bold())
                            .foregroundStyle(gold)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Total XP

    private var totalXPSection: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL XP")
                        .font(.caption.bold())
                        .foregroundStyle(subtleText)
                        .tracking(1.2)

                    Text(formattedXP(engine.state.xp))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(gold)
                }

                Spacer()

                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(gold.opacity(0.6))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func formattedXP(_ xp: Int) -> String {
        if xp >= 1_000_000 {
            return String(format: "%.1fM", Double(xp) / 1_000_000)
        } else if xp >= 1_000 {
            return String(format: "%.1fK", Double(xp) / 1_000)
        }
        return "\(xp)"
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#1e293b").opacity(0.6))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#94a3b8"))

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#64748b"))
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environmentObject(GameEngine())
}
