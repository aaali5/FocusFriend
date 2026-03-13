import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var engine: GameEngine

    @State private var selectedQuestCategory: QuestCategory = .daily
    @State private var selectedSkillNode: SkillNode?
    @State private var showUnlockConfirm = false
    @State private var showAscendConfirm = false

    private var currentBoss: Boss {
        bosses[engine.state.currentBossIndex % bosses.count]
    }

    private var hpFraction: Double {
        guard engine.state.bossMaxHP > 0 else { return 0 }
        return Double(engine.state.bossHP) / Double(engine.state.bossMaxHP)
    }

    private var bossColor: Color {
        Color(hex: currentBoss.color)
    }

    private var filteredQuests: [Quest] {
        quests.filter { $0.category == selectedQuestCategory }
    }

    private var skillPoints: Int { engine.state.skillPoints }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                journeyHeader

                // Prestige banner (only when eligible)
                if engine.canAscend {
                    ascendBanner
                }

                // Active Boss (compact arena card)
                bossSection

                // Active Quests (all categories with pill tabs)
                questsSection

                // Skill Tree
                skillTreeSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.navyBg.ignoresSafeArea())
        .alert("Ascend", isPresented: $showAscendConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Ascend") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    engine.ascend()
                }
            }
        } message: {
            Text("Reset to Level 1, clear skills, and gain a Prestige Star (+5% permanent XP bonus). Your streak, history, and boss kills are kept. Bosses get harder.\n\nPrestige \(engine.state.prestigeLevel) → \(engine.state.prestigeLevel + 1)")
        }
        .alert("Unlock Skill", isPresented: $showUnlockConfirm) {
            Button("Cancel", role: .cancel) {
                selectedSkillNode = nil
            }
            Button("Unlock") {
                if let node = selectedSkillNode {
                    engine.unlockSkill(node.id)
                }
                selectedSkillNode = nil
            }
        } message: {
            if let node = selectedSkillNode {
                Text("Spend 1 skill point to unlock \(node.name)?\n\n\(node.description)")
            }
        }
    }

    // MARK: - Journey Header

    private var journeyHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "map.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Journey")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Prestige stars
            if engine.state.prestigeLevel > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(engine.state.prestigeLevel, 5), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#fbbf24"))
                    }
                    if engine.state.prestigeLevel > 5 {
                        Text("+\(engine.state.prestigeLevel - 5)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#fbbf24"))
                    }
                }
            }

            Spacer()

            // Skill points counter
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                Text("\(skillPoints)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("SP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.xpGold.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.xpGold.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(Color.xpGold)
        }
    }

    // MARK: - Ascend Banner

    private var ascendBanner: some View {
        Button {
            showAscendConfirm = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "#fbbf24"))
                    .shadow(color: Color(hex: "#fbbf24").opacity(0.5), radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Ascend")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Reset to Lv.1 for a Prestige Star & +5% XP forever")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "#fbbf24").opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#fbbf24").opacity(0.15), Color(hex: "#f97316").opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(hex: "#fbbf24").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Boss Section (compact)

    private var bossSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Boss header row
                HStack(spacing: 14) {
                    // Boss emoji
                    Text(currentBoss.emoji)
                        .font(.system(size: 48))
                        .shadow(color: bossColor.opacity(0.5), radius: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentBoss.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(currentBoss.type)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(bossColor.opacity(0.9))
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }

                    Spacer()

                    // HP percentage
                    Text("\(Int(hpFraction * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(hpColor)
                }

                // HP bar
                GeometryReader { geo in
                    let width = geo.size.width

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: hpGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, width * hpFraction))
                            .animation(.easeOut(duration: 0.5), value: engine.state.bossHP)

                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                hpFraction < 0.25
                                    ? Color.red.opacity(0.5)
                                    : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                    }
                }
                .frame(height: 16)

                // Damage stats row
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("\(engine.state.bossHP)/\(engine.state.bossMaxHP)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("HP")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("\(engine.state.bossDamageThisWeek)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.foxOrange)
                        Text("DMG This Week")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("\(engine.state.bossDefeats)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.bossRed)
                        Text("Boss Kills")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var hpColor: Color {
        if hpFraction < 0.25 { return .red }
        if hpFraction < 0.50 { return .orange }
        return bossColor
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

    // MARK: - Quests Section

    private var questsSection: some View {
        VStack(spacing: 14) {
            // Section header
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundStyle(categoryColor(selectedQuestCategory))
                Text("Quests")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()

                let completedCount = quests.filter { engine.state.questCompleted[$0.id] == true }.count
                Text("\(completedCount)/\(quests.count)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Category pill tabs
            HStack(spacing: 10) {
                ForEach(QuestCategory.allCases, id: \.rawValue) { category in
                    let isSelected = selectedQuestCategory == category
                    let color = categoryColor(category)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedQuestCategory = category
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

            // Quest cards
            ForEach(filteredQuests) { quest in
                questCard(
                    quest: quest,
                    progress: engine.state.questProgress[quest.id] ?? 0,
                    isCompleted: engine.state.questCompleted[quest.id] == true,
                    accentColor: categoryColor(quest.category)
                )
            }
        }
    }

    // MARK: - Quest Card (duplicated from QuestBoardView since it's private there)

    @ViewBuilder
    private func questCard(quest: Quest, progress: Double, isCompleted: Bool, accentColor: Color) -> some View {
        let progressFraction: Double = {
            guard quest.target > 0 else { return 0 }
            return min(progress / quest.target, 1.0)
        }()

        let progressLabel: String = {
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
        }()

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

                Text(progressLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isCompleted ? .white.opacity(0.3) : .white.opacity(0.6))
                    .frame(minWidth: 54, alignment: .trailing)
            }

            // Completed checkmark
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

    // MARK: - Skill Tree Section

    private var skillTreeSection: some View {
        VStack(spacing: 14) {
            // Section header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.xpGold)
                Text("Skill Tree")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("Unlock abilities with SP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Branch columns
            HStack(alignment: .top, spacing: 12) {
                ForEach(SkillBranch.allCases, id: \.rawValue) { branch in
                    branchColumn(branch)
                }
            }
        }
    }

    // MARK: - Branch Column

    private func branchColumn(_ branch: SkillBranch) -> some View {
        let branchColor = Color(hex: branch.color)
        let nodes = skillTree
            .filter { $0.branch == branch }
            .sorted { $0.tier < $1.tier }

        return VStack(spacing: 0) {
            // Branch label
            Text(branch.label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(branchColor)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.bottom, 16)

            // Nodes with connector lines
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                let isUnlocked = engine.state.skills[node.id] == true
                let isAvailable = nodeIsAvailable(node)

                // Connector line (skip for first)
                if index > 0 {
                    connectorLine(
                        color: branchColor,
                        isUnlocked: isUnlocked,
                        previousUnlocked: engine.state.skills[nodes[index - 1].id] == true
                    )
                }

                // Node
                skillNodeView(
                    node: node,
                    isUnlocked: isUnlocked,
                    isAvailable: isAvailable,
                    branchColor: branchColor
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Connector Line

    private func connectorLine(color: Color, isUnlocked: Bool, previousUnlocked: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            previousUnlocked ? color.opacity(0.5) : Color.white.opacity(0.1),
                            isUnlocked ? color.opacity(0.5) : Color.white.opacity(0.1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 24)
        }
    }

    // MARK: - Skill Node

    private func skillNodeView(
        node: SkillNode,
        isUnlocked: Bool,
        isAvailable: Bool,
        branchColor: Color
    ) -> some View {
        Button {
            if isAvailable && !isUnlocked && skillPoints > 0 {
                selectedSkillNode = node
                showUnlockConfirm = true
            }
        } label: {
            VStack(spacing: 8) {
                // Circle icon
                ZStack {
                    if isUnlocked {
                        Circle()
                            .fill(branchColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Circle()
                            .strokeBorder(branchColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }

                    Circle()
                        .fill(
                            isUnlocked
                                ? branchColor.opacity(0.25)
                                : isAvailable
                                    ? Color.white.opacity(0.1)
                                    : Color.white.opacity(0.04)
                        )
                        .frame(width: 44, height: 44)

                    Circle()
                        .strokeBorder(
                            isUnlocked
                                ? branchColor.opacity(0.6)
                                : isAvailable
                                    ? Color.white.opacity(0.25)
                                    : Color.white.opacity(0.08),
                            lineWidth: 1.5
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: nodeIcon(isUnlocked: isUnlocked, isAvailable: isAvailable))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            isUnlocked
                                ? branchColor
                                : isAvailable
                                    ? .white.opacity(0.7)
                                    : .white.opacity(0.2)
                        )
                }

                // Tier badge
                Text("T\(node.tier)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        isUnlocked ? branchColor.opacity(0.7) : .white.opacity(0.25)
                    )

                // Name
                Text(node.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        isUnlocked
                            ? .white
                            : isAvailable
                                ? .white.opacity(0.7)
                                : .white.opacity(0.3)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Description
                Text(node.description)
                    .font(.system(size: 9))
                    .foregroundStyle(
                        isUnlocked ? .white.opacity(0.5) : .white.opacity(0.2)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isUnlocked
                            ? branchColor.opacity(0.25)
                            : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isUnlocked ? branchColor.opacity(0.2) : .clear,
                radius: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(isUnlocked || !isAvailable || skillPoints <= 0)
    }

    // MARK: - Helpers

    private func nodeIsAvailable(_ node: SkillNode) -> Bool {
        if engine.state.skills[node.id] == true { return true }
        if let req = node.requires {
            return engine.state.skills[req] == true
        }
        return true
    }

    private func nodeIcon(isUnlocked: Bool, isAvailable: Bool) -> String {
        if isUnlocked { return "checkmark" }
        if isAvailable { return "circle.fill" }
        return "lock.fill"
    }

    private func categoryColor(_ category: QuestCategory) -> Color {
        switch category {
        case .daily:   return Color(hex: "#38bdf8")
        case .weekly:  return Color(hex: "#7c3aed")
        case .epic:    return Color(hex: "#fbbf24")
        }
    }

    private func categoryIcon(_ category: QuestCategory) -> String {
        switch category {
        case .daily:   return "sun.max.fill"
        case .weekly:  return "calendar"
        case .epic:    return "star.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    JourneyView()
        .environmentObject(GameEngine())
}
