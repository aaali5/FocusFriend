import SwiftUI

// MARK: - Tab Definition

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case focus
    case journey

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:    return "Home"
        case .focus:   return "Focus"
        case .journey: return "Journey"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .focus:   return "timer"
        case .journey: return "map.fill"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject private var engine: GameEngine
    @State private var selectedTab: AppTab = .focus
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
                case .home:
                    HomeView()
                case .focus:
                    FocusTimerView()
                case .journey:
                    JourneyView()
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
