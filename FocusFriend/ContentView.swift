import SwiftUI

// MARK: - Tab Definition

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case timer
    case quests
    case battle
    case skills
    case streak
    case stats

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Home"
        case .timer:     return "Timer"
        case .quests:    return "Quests"
        case .battle:    return "Battle"
        case .skills:    return "Skills"
        case .streak:    return "Streak"
        case .stats:     return "Stats"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .timer:     return "timer"
        case .quests:    return "scroll.fill"
        case .battle:    return "shield.fill"
        case .skills:    return "sparkles"
        case .streak:    return "flame.fill"
        case .stats:     return "chart.bar.fill"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject private var engine: GameEngine
    @State private var selectedTab: AppTab = .dashboard
    @Namespace private var tabAnimation

    private let darkNavy = Color(red: 0.04, green: 0.055, blue: 0.1)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen dark background
            darkNavy
                .ignoresSafeArea()

            // Tab content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .timer:
                    FocusTimerView()
                case .quests:
                    QuestBoardView()
                case .battle:
                    BossBattleView()
                case .skills:
                    SkillTreeView()
                case .streak:
                    StreakTrackerView()
                case .stats:
                    StatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80) // Space for custom tab bar

            // Custom tab bar
            TabBarView(selectedTab: $selectedTab, namespace: tabAnimation)
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameEngine())
}
