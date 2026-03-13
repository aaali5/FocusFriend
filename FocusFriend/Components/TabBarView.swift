import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: AppTab
    var namespace: Namespace.ID

    // The 5 primary tabs always visible
    private let primaryTabs: [AppTab] = [.dashboard, .timer, .quests, .battle, .skills]
    // The overflow tabs behind "More"
    private let overflowTabs: [AppTab] = [.streak, .stats]

    @State private var showOverflow = false

    private let foxOrange = Color(red: 0.976, green: 0.451, blue: 0.086) // #f97316
    private let inactiveGray = Color.white.opacity(0.45)
    private let darkNavy = Color(red: 0.04, green: 0.055, blue: 0.1)

    var body: some View {
        VStack(spacing: 0) {
            // Overflow menu (slides up when "More" is tapped)
            if showOverflow {
                overflowMenu
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main tab bar
            mainTabBar
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showOverflow)
    }

    // MARK: - Main Tab Bar

    private var mainTabBar: some View {
        HStack(spacing: 0) {
            ForEach(primaryTabs) { tab in
                tabButton(tab)
            }

            // More button
            moreButton
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            glassBackground
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 2)
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
                showOverflow = false
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(foxOrange.opacity(0.15))
                            .frame(width: 40, height: 28)
                            .matchedGeometryEffect(id: "activeBackground", in: namespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? foxOrange : inactiveGray)
                }
                .frame(height: 28)

                Text(tab.label)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? foxOrange : inactiveGray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - More Button

    private var moreButton: some View {
        let isOverflowActive = overflowTabs.contains(selectedTab)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                showOverflow.toggle()
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isOverflowActive && !showOverflow {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(foxOrange.opacity(0.15))
                            .frame(width: 40, height: 28)
                    }

                    Image(systemName: showOverflow ? "xmark" : "ellipsis")
                        .font(.system(size: 18, weight: isOverflowActive ? .semibold : .regular))
                        .foregroundStyle(isOverflowActive ? foxOrange : inactiveGray)
                        .rotationEffect(.degrees(showOverflow ? 90 : 0))
                }
                .frame(height: 28)

                Text("More")
                    .font(.system(size: 10, weight: isOverflowActive ? .semibold : .regular))
                    .foregroundStyle(isOverflowActive ? foxOrange : inactiveGray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overflow Menu

    private var overflowMenu: some View {
        HStack(spacing: 16) {
            ForEach(overflowTabs) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                        showOverflow = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? foxOrange : .white.opacity(0.7))

                        Text(tab.label)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundStyle(selectedTab == tab ? foxOrange : .white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? foxOrange.opacity(0.12) : Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .dashboard
    @Previewable @Namespace var ns

    ZStack {
        Color(red: 0.04, green: 0.055, blue: 0.1)
            .ignoresSafeArea()

        VStack {
            Spacer()
            TabBarView(selectedTab: $tab, namespace: ns)
        }
    }
}
