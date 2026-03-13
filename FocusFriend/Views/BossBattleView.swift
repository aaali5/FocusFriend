import SwiftUI

// MARK: - Boss Battle View

struct BossBattleView: View {
    @EnvironmentObject private var engine: GameEngine

    @State private var pulseScale: CGFloat = 1.0
    @State private var emojiFloat: CGFloat = 0

    private var currentBoss: Boss {
        bosses[engine.state.currentBossIndex % bosses.count]
    }

    private var hpFraction: Double {
        guard engine.state.bossMaxHP > 0 else { return 0 }
        return Double(engine.state.bossHP) / Double(engine.state.bossMaxHP)
    }

    private var hpPercentage: Int {
        Int(hpFraction * 100)
    }

    private var isLowHP: Bool {
        hpFraction < 0.25 && hpFraction > 0
    }

    private var bossColor: Color {
        Color(hex: currentBoss.color)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Boss Battle")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Focus to deal damage")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundStyle(.bossRed)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Arena card
                arenaCard

                // Stats row
                statsRow
                    .padding(.horizontal)

                // Boss roster
                bossRoster
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.navyBg)
    }

    // MARK: - Arena Card

    private var arenaCard: some View {
        VStack(spacing: 20) {
            // Boss emoji
            Text(currentBoss.emoji)
                .font(.system(size: 80))
                .shadow(color: bossColor.opacity(0.6), radius: 20)
                .scaleEffect(pulseScale)
                .offset(y: emojiFloat)
                .onAppear {
                    // Floating animation
                    withAnimation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        emojiFloat = -8
                    }

                    // Pulse when low HP
                    if isLowHP {
                        withAnimation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.08
                        }
                    }
                }
                .onChange(of: isLowHP) { _, low in
                    if low {
                        withAnimation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.08
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.3)) {
                            pulseScale = 1.0
                        }
                    }
                }

            // Boss name + type
            VStack(spacing: 6) {
                Text(currentBoss.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(currentBoss.type)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(bossColor.opacity(0.9))
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(currentBoss.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
            }

            // HP bar
            hpBar

            // HP numbers
            HStack {
                Text("\(hpPercentage)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(hpGradientColor)

                Spacer()

                Text("\(engine.state.bossHP) / \(engine.state.bossMaxHP) HP")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isLowHP
                        ? Color.red.opacity(0.3)
                        : bossColor.opacity(0.15),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
    }

    // MARK: - HP Bar

    private var hpBar: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))

                // HP fill with gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: hpGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, width * hpFraction))
                    .animation(.easeOut(duration: 0.5), value: engine.state.bossHP)

                // Tick marks at 25%, 50%, 75%
                ForEach([0.25, 0.50, 0.75], id: \.self) { tick in
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1.5, height: 10)
                        .position(x: width * tick, y: 10)
                }

                // Glow border
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isLowHP
                            ? Color.red.opacity(0.5)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            }
        }
        .frame(height: 20)
    }

    private var hpGradientColors: [Color] {
        if hpFraction < 0.25 {
            return [Color.red, Color.red.opacity(0.7)]
        } else if hpFraction < 0.5 {
            return [bossColor, Color.red.opacity(0.8)]
        } else {
            return [bossColor, bossColor.opacity(0.7)]
        }
    }

    private var hpGradientColor: Color {
        if hpFraction < 0.25 { return .red }
        if hpFraction < 0.50 { return .orange }
        return bossColor
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(engine.state.bossDamageThisWeek)",
                label: "DMG This Week",
                color: .foxOrange
            )
            divider
            statCell(
                value: "\(engine.state.bossDefeats)",
                label: "Boss Kills",
                color: .bossRed
            )
            divider
            statCell(
                value: "\(engine.state.totalSessions)",
                label: "Total Sessions",
                color: .spiritBlue
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }

    // MARK: - Boss Roster

    private var bossRoster: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Boss Roster")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                ForEach(Array(bosses.enumerated()), id: \.element.id) { index, boss in
                    let isActive = index == (engine.state.currentBossIndex % bosses.count)
                    let color = Color(hex: boss.color)

                    VStack(spacing: 8) {
                        Text(boss.emoji)
                            .font(.system(size: 36))
                            .shadow(
                                color: isActive ? color.opacity(0.5) : .clear,
                                radius: 10
                            )

                        Text(boss.name)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(isActive ? .white : .white.opacity(0.4))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(boss.type)
                            .font(.system(size: 10))
                            .foregroundStyle(isActive ? color.opacity(0.8) : .white.opacity(0.25))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                isActive
                                    ? color.opacity(0.12)
                                    : Color.white.opacity(0.04)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isActive
                                    ? color.opacity(0.4)
                                    : Color.white.opacity(0.06),
                                lineWidth: isActive ? 1.5 : 1
                            )
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BossBattleView()
        .environmentObject(GameEngine())
}
