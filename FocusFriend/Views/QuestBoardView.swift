import SwiftUI

// MARK: - Quest Board View

struct QuestBoardView: View {
    @EnvironmentObject private var engine: GameEngine
    @State private var selectedCategory: QuestCategory = .daily

    private var visibleQuests: [Quest] {
        engine.activeQuests()
    }

    private var filteredQuests: [Quest] {
        visibleQuests.filter { $0.category == selectedCategory }
    }

    private var completedCount: Int {
        visibleQuests.filter { engine.state.questCompleted[$0.id] == true }.count
    }

    private var totalAvailableXP: Int {
        visibleQuests.reduce(0) { $0 + $1.xpReward }
    }

    private var earnedXP: Int {
        visibleQuests
            .filter { engine.state.questCompleted[$0.id] == true }
            .reduce(0) { $0 + $1.xpReward }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quest Board")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Complete quests to earn XP")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "scroll.fill")
                        .font(.title2)
                        .foregroundStyle(categoryColor(selectedCategory))
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Category pill tabs
                categoryTabs

                // Quest cards
                LazyVStack(spacing: 14) {
                    ForEach(filteredQuests) { quest in
                        QuestCardView(
                            quest: quest,
                            progress: engine.state.questProgress[quest.id] ?? 0,
                            isCompleted: engine.state.questCompleted[quest.id] == true,
                            accentColor: categoryColor(quest.category)
                        )
                    }
                }
                .padding(.horizontal)

                // Summary footer
                summaryFooter
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.navyBg)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        HStack(spacing: 10) {
            ForEach(QuestCategory.allCases, id: \.rawValue) { category in
                let isSelected = selectedCategory == category
                let color = categoryColor(category)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: categoryIcon(category))
                            .font(.caption)
                        Text(category.label)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? color.opacity(0.25) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? color.opacity(0.6) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(isSelected ? color : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(completedCount)/\(visibleQuests.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Completed")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 36)

            VStack(spacing: 4) {
                Text(formatNumber(earnedXP))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.xpGold)
                Text("XP Earned")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 36)

            VStack(spacing: 4) {
                Text(formatNumber(totalAvailableXP))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Total XP")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
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

    // MARK: - Helpers

    private func categoryColor(_ category: QuestCategory) -> Color {
        switch category {
        case .daily:   return Color(hex: "#38bdf8")  // cyan
        case .weekly:  return Color(hex: "#7c3aed")  // purple
        case .epic:    return Color(hex: "#fbbf24")  // gold
        }
    }

    private func categoryIcon(_ category: QuestCategory) -> String {
        switch category {
        case .daily:   return "sun.max.fill"
        case .weekly:  return "calendar"
        case .epic:    return "star.fill"
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10_000 {
            return "\(n / 1000)k"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Quest Card View

private struct QuestCardView: View {
    let quest: Quest
    let progress: Double
    let isCompleted: Bool
    let accentColor: Color

    private var progressFraction: Double {
        guard quest.target > 0 else { return 0 }
        return min(progress / quest.target, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: title + XP badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isCompleted ? .white.opacity(0.4) : .white)
                        .strikethrough(isCompleted, color: .white.opacity(0.3))

                    Text(quest.description)
                        .font(.system(size: 13))
                        .foregroundStyle(isCompleted ? .white.opacity(0.25) : .white.opacity(0.55))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                // XP reward badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                    Text("+\(quest.xpReward) XP")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isCompleted ? Color.white.opacity(0.06) : accentColor.opacity(0.2))
                )
                .foregroundStyle(isCompleted ? .white.opacity(0.3) : accentColor)
            }

            // Progress bar + count
            HStack(spacing: 10) {
                // Progress bar
                GeometryReader { geo in
                    let width = geo.size.width

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))

                        Capsule()
                            .fill(
                                isCompleted
                                    ? AnyShapeStyle(Color.white.opacity(0.15))
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [accentColor, accentColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .frame(width: max(6, width * progressFraction))
                    }
                }
                .frame(height: 6)

                // Count label
                Text(progressLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isCompleted ? .white.opacity(0.3) : .white.opacity(0.6))
                    .frame(minWidth: 54, alignment: .trailing)
            }

            // Completed checkmark overlay
            if isCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Completed")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.green.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isCompleted
                        ? Color.green.opacity(0.15)
                        : accentColor.opacity(0.12),
                    lineWidth: 1
                )
        )
        .opacity(isCompleted ? 0.7 : 1.0)
    }

    private var progressLabel: String {
        let current: String
        if progress == floor(progress) {
            current = "\(Int(progress))"
        } else {
            current = String(format: "%.1f", progress)
        }
        let target: String
        if quest.target == floor(quest.target) {
            target = "\(Int(quest.target))"
        } else {
            target = String(format: "%.1f", quest.target)
        }
        return "\(current)/\(target) \(quest.unit)"
    }
}

// MARK: - Preview

#Preview {
    QuestBoardView()
        .environmentObject(GameEngine())
}
