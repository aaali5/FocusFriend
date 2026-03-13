import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var engine: GameEngine

    // MARK: - Colors

    private let navyBg = Color(hex: "#0f172a")
    private let gold = Color(hex: "#fbbf24")
    private let foxOrange = Color(hex: "#f97316")
    private let subtleText = Color(hex: "#94a3b8")
    private let dimText = Color(hex: "#64748b")

    private let heatmapColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        let stage = GameEngine.evolutionStage(for: engine.state.level)
        let xpProgress = GameEngine.xpProgress(totalXP: engine.state.xp)
        let stageColor = Color(hex: stage.color)
        let streakMult = GameEngine.streakMultiplier(engine.state.streakDays)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Fox + Level section (from DashboardView)
                foxSection(stage: stage, stageColor: stageColor)
                levelSection(
                    level: engine.state.level,
                    xpProgress: xpProgress,
                    streakMult: streakMult
                )

                // Quick stats row (2x2 grid)
                statGrid

                // Streak flame + multiplier (compact)
                streakSection

                // 30-day heatmap
                heatmapSection

                // Weekly chart
                weeklyChart

                // Evolution progress
                evolutionProgressSection(stage: stage, stageColor: stageColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(navyBg.ignoresSafeArea())
    }

    // MARK: - Fox Section

    @ViewBuilder
    private func foxSection(stage: EvolutionStage, stageColor: Color) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                FoxView(stage: stage, size: 180, isAnimating: true)
                    .frame(height: 190)

                HStack(spacing: 6) {
                    Text(stage.name)
                        .font(.title2.bold())
                        .foregroundStyle(stageColor)

                    if engine.state.prestigeLevel > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(engine.state.prestigeLevel, 5), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: "#fbbf24"))
                            }
                            if engine.state.prestigeLevel > 5 {
                                Text("+\(engine.state.prestigeLevel - 5)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "#fbbf24"))
                            }
                        }
                    }
                }

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

    // MARK: - Streak Section (compact)

    private var streakSection: some View {
        let multiplier = GameEngine.streakMultiplier(engine.state.streakDays)

        return GlassCard {
            HStack(spacing: 16) {
                // Flame icon
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, Color(red: 1.0, green: 0.84, blue: 0.0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 10, y: 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(engine.state.streakDays) day streak")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("\(multiplier, specifier: "%.1f")x XP")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(multiplier > 1 ? .yellow : .white.opacity(0.5))
                        }

                        Text("  |  ")
                            .foregroundStyle(.white.opacity(0.2))

                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow.opacity(0.7))
                            Text("Best: \(engine.state.bestStreak)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()

                // Streak shields
                VStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                    Text("\(engine.state.streakShields)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Shields")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - 30-Day Heatmap

    private var heatmapSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.orange)
                    Text("30-Day Heatmap")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                let days = heatmapDays()
                let maxMinutes = max(days.map(\.minutes).max() ?? 1, 1)

                LazyVGrid(columns: heatmapColumns, spacing: 6) {
                    ForEach(days, id: \.date) { day in
                        let intensity = Double(day.minutes) / Double(maxMinutes)
                        let isToday = day.date == todayString()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(cellColor(intensity: intensity))
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
                            )
                            .overlay(
                                Text(dayLabel(day.date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(day.minutes > 0 ? 0.9 : 0.3))
                            )
                    }
                }

                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { val in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(intensity: val))
                            .frame(width: 14, height: 14)
                    }
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyChart: some View {
        let data = paddedWeeklyData()
        let weeklyTotal = data.reduce(0, +)
        let maxVal = max(data.max() ?? 1, 1)
        let todayIndex = currentDayOfWeekIndex()

        return GlassCard {
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

    // MARK: - Helpers

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func heatmapDays() -> [FocusDay] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        let today = Date()

        var days: [FocusDay] = []
        for offset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dateStr = formatter.string(from: date)
            if let existing = engine.state.focusHistory.first(where: { $0.date == dateStr }) {
                days.append(existing)
            } else {
                days.append(FocusDay(date: dateStr, minutes: 0))
            }
        }
        return days
    }

    private func dayLabel(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "" }
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private func cellColor(intensity: Double) -> Color {
        if intensity <= 0 {
            return Color.white.opacity(0.06)
        }
        let r = 0.6 + intensity * 0.4
        let g = 0.3 + intensity * 0.54
        let b = 0.0 + intensity * 0.0
        return Color(red: r, green: g, blue: b).opacity(0.3 + intensity * 0.7)
    }

    private func paddedWeeklyData() -> [Int] {
        var data = engine.state.weeklyFocusMinutes
        while data.count < 7 { data.insert(0, at: 0) }
        return Array(data.suffix(7))
    }

    private func currentDayOfWeekIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(GameEngine())
}
