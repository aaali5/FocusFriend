import SwiftUI

// MARK: - Skill Tree View

struct SkillTreeView: View {
    @EnvironmentObject private var engine: GameEngine
    @State private var selectedNode: SkillNode?
    @State private var showUnlockConfirm = false

    private var skillPoints: Int { engine.state.skillPoints }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skill Tree")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Unlock abilities with skill points")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
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
                    .foregroundStyle(.xpGold)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Branch columns
                HStack(alignment: .top, spacing: 12) {
                    ForEach(SkillBranch.allCases, id: \.rawValue) { branch in
                        branchColumn(branch)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color.navyBg)
        .alert("Unlock Skill", isPresented: $showUnlockConfirm) {
            Button("Cancel", role: .cancel) {
                selectedNode = nil
            }
            Button("Unlock") {
                if let node = selectedNode {
                    engine.unlockSkill(node.id)
                }
                selectedNode = nil
            }
        } message: {
            if let node = selectedNode {
                Text("Spend 1 skill point to unlock \(node.name)?\n\n\(node.description)")
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

                // Connector line (above node, skip for first)
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
                selectedNode = node
                showUnlockConfirm = true
            }
        } label: {
            VStack(spacing: 8) {
                // Circle icon
                ZStack {
                    // Glow ring for unlocked
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

                    // Icon
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
        return true // Tier 1 nodes are always available
    }

    private func nodeIcon(isUnlocked: Bool, isAvailable: Bool) -> String {
        if isUnlocked { return "checkmark" }
        if isAvailable { return "circle.fill" }
        return "lock.fill"
    }
}

// MARK: - Preview

#Preview {
    SkillTreeView()
        .environmentObject(GameEngine())
}
