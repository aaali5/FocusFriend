import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var engine: GameEngine

    private let darkNavy = Color(red: 0.04, green: 0.055, blue: 0.1)
    private let statColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Header
                header

                // MARK: - Main Stats Grid
                mainStatsGrid

                // MARK: - Weekly Bar Chart
                weeklyChart

                // MARK: - RPG Progress
                rpgProgress
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(darkNavy.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Focus Analytics")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: - Main Stats Grid (2x2)

    private var mainStatsGrid: some View {
        let totalHours = Double(engine.state.totalFocusMinutes) / 60.0
        let avgSession: Double = engine.state.totalSessions > 0
            ? Double(engine.state.totalFocusMinutes) / Double(engine.state.totalSessions)
            : 0

        return LazyVGrid(columns: statColumns, spacing: 12) {
            statCard(
                icon: "clock.fill",
                iconColor: .cyan,
                value: String(format: "%.1f", totalHours),
                label: "Total Hours"
            )
            statCard(
                icon: "bolt.fill",
                iconColor: .yellow,
                value: "\(engine.state.totalSessions)",
                label: "Total Sessions"
            )
            statCard(
                icon: "gauge.medium",
                iconColor: .green,
                value: String(format: "%.0f", avgSession),
                label: "Avg Session (min)"
            )
            statCard(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(engine.state.bestStreak)",
                label: "Best Streak"
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        glassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyChart: some View {
        let data = paddedWeeklyData()
        let weeklyTotal = data.reduce(0, +)
        let maxVal = max(data.max() ?? 1, 1)
        let todayIndex = currentDayOfWeekIndex()

        return glassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.cyan)
                    Text("This Week")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(weeklyTotal) min")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.cyan)
                }

                // Bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        let minutes = data[index]
                        let height = maxVal > 0
                            ? max(CGFloat(minutes) / CGFloat(maxVal), 0.05)
                            : 0.05
                        let isToday = index == todayIndex

                        VStack(spacing: 6) {
                            // Value label
                            Text("\(minutes)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(minutes > 0 ? 0.7 : 0.3))

                            // Bar
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: isToday
                                            ? [.cyan, .blue]
                                            : [.cyan.opacity(0.5), .blue.opacity(0.5)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: 120 * height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isToday ? .white.opacity(0.4) : .clear, lineWidth: 1.5)
                                )

                            // Day label
                            Text(dayLabels[index])
                                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? .cyan : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - RPG Progress

    private var rpgProgress: some View {
        let stage = GameEngine.evolutionStage(for: engine.state.level)
        let stageColor = Color(hex: stage.color)
        let skillsUnlocked = engine.state.skills.values.filter { $0 }.count
        let questsDone = engine.state.questCompleted.values.filter { $0 }.count

        return glassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(.purple)
                    Text("RPG Progress")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                rpgRow(icon: "star.fill", color: .yellow, label: "Current Level", value: "\(engine.state.level)")
                Divider().overlay(Color.white.opacity(0.06))

                rpgRow(icon: "sparkles", color: stageColor, label: "Evolution Stage") {
                    Text(stage.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stageColor)
                }
                Divider().overlay(Color.white.opacity(0.06))

                rpgRow(icon: "shield.slash.fill", color: .red, label: "Bosses Defeated", value: "\(engine.state.bossDefeats)")
                Divider().overlay(Color.white.opacity(0.06))

                rpgRow(icon: "bolt.circle.fill", color: .cyan, label: "Total XP Earned", value: formattedXP(engine.state.xp))
                Divider().overlay(Color.white.opacity(0.06))

                rpgRow(icon: "wand.and.stars", color: .green, label: "Skills Unlocked", value: "\(skillsUnlocked) / \(skillTree.count)")
                Divider().overlay(Color.white.opacity(0.06))

                rpgRow(icon: "scroll.fill", color: .orange, label: "Quests Completed", value: "\(questsDone)")
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Subviews & Helpers

    private func rpgRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private func rpgRow<V: View>(icon: String, color: Color, label: String, @ViewBuilder valueView: () -> V) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            valueView()
        }
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }

    /// Pads or trims weeklyFocusMinutes to exactly 7 entries (Mon-Sun).
    private func paddedWeeklyData() -> [Int] {
        var data = engine.state.weeklyFocusMinutes
        while data.count < 7 { data.insert(0, at: 0) }
        return Array(data.suffix(7))
    }

    /// Returns 0-based index for today: 0=Mon ... 6=Sun.
    private func currentDayOfWeekIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar: 1=Sun, 2=Mon ... 7=Sat -> convert to 0=Mon ... 6=Sun
        return (weekday + 5) % 7
    }

    /// Formats large XP numbers with comma separators.
    private func formattedXP(_ xp: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}


#Preview {
    StatsView()
        .environmentObject(GameEngine())
}
