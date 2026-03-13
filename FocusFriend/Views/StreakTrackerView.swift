import SwiftUI

struct StreakTrackerView: View {
    @EnvironmentObject private var engine: GameEngine

    private let darkNavy = Color(red: 0.04, green: 0.055, blue: 0.1)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)

    @State private var flamePulse = false

    // Streak milestones: (days required, multiplier label, description)
    private let milestones: [(days: Int, label: String, desc: String)] = [
        (3, "1.5x", "Warm-Up Streak"),
        (7, "2x", "Weekly Warrior"),
        (14, "3x", "Fortnight Fire"),
        (30, "5x", "Monthly Master"),
        (60, "", "Double Down"),
        (90, "", "Quarter Champion"),
        (365, "", "Year of Focus"),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Flame Header
                flameHeader

                // MARK: - Streak Stats Row
                streakStatsRow

                // MARK: - Multiplier Badge
                multiplierBadge

                // MARK: - 30-Day Heatmap
                heatmapSection

                // MARK: - Milestones
                milestonesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(darkNavy.ignoresSafeArea())
        .onAppear {
            flamePulse = true
        }
    }

    // MARK: - Flame Header

    private var flameHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer glow
                Image(systemName: "flame.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.84, blue: 0.0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .blur(radius: 20)
                    .opacity(0.6)
                    .scaleEffect(flamePulse ? 1.15 : 0.95)

                // Main flame
                Image(systemName: "flame.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.84, blue: 0.0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .shadow(color: .orange.opacity(0.8), radius: 16, y: 4)
                    .scaleEffect(flamePulse ? 1.05 : 0.95)
            }
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: flamePulse
            )

            // Giant streak number
            Text("\(engine.state.streakDays)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, Color(red: 1.0, green: 0.84, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 12)

            Text("day streak")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(2)
        }
        .padding(.top, 8)
    }

    // MARK: - Streak Stats Row

    private var streakStatsRow: some View {
        HStack(spacing: 16) {
            // Streak Shields
            glassCard {
                VStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                    Text("\(engine.state.streakShields)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Shields")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }

            // Best Streak
            glassCard {
                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    Text("\(engine.state.bestStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Best Streak")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Multiplier Badge

    private var multiplierBadge: some View {
        let multiplier = GameEngine.streakMultiplier(engine.state.streakDays)

        return glassCard {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak Multiplier")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(multiplier, specifier: "%.1f")x XP")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            multiplier >= 5
                                ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(.white)
                        )
                }

                Spacer()

                if multiplier > 1 {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - 30-Day Heatmap

    private var heatmapSection: some View {
        glassCard {
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

                LazyVGrid(columns: columns, spacing: 6) {
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

    // MARK: - Milestones

    private var milestonesSection: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(.orange)
                    Text("Milestones")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                ForEach(milestones, id: \.days) { milestone in
                    let completed = engine.state.streakDays >= milestone.days
                    let progress = min(Double(engine.state.streakDays) / Double(milestone.days), 1.0)

                    HStack(spacing: 12) {
                        // Checkmark or target
                        if completed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                        } else {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.3))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(milestone.days) Days")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(completed ? .white : .white.opacity(0.6))

                                if !milestone.label.isEmpty {
                                    Text(milestone.label)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(completed ? .yellow : .gray.opacity(0.4))
                                        )
                                }

                                Spacer()

                                Text(milestone.desc)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            if !completed {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(.white.opacity(0.1))
                                            .frame(height: 6)

                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, Color(red: 1.0, green: 0.84, blue: 0.0)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * progress, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }

                    if milestone.days != milestones.last?.days {
                        Divider()
                            .overlay(Color.white.opacity(0.06))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Builds the last 30 days as FocusDay entries, filling missing days with 0 minutes.
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

    /// Returns the day-of-month number as a short label.
    private func dayLabel(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "" }
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    /// Maps an intensity value (0...1) to a color from dark gray through orange to gold.
    private func cellColor(intensity: Double) -> Color {
        if intensity <= 0 {
            return Color.white.opacity(0.06)
        }
        // Interpolate from dim orange to bright gold
        let r = 0.6 + intensity * 0.4     // 0.6 -> 1.0
        let g = 0.3 + intensity * 0.54    // 0.3 -> 0.84
        let b = 0.0 + intensity * 0.0     // stays warm
        return Color(red: r, green: g, blue: b).opacity(0.3 + intensity * 0.7)
    }
}

#Preview {
    StreakTrackerView()
        .environmentObject(GameEngine())
}
