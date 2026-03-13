import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: AppTab
    var namespace: Namespace.ID

    private let foxOrange = Color(red: 0.976, green: 0.451, blue: 0.086) // #f97316
    private let inactiveGray = Color.white.opacity(0.45)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(glassBackground)
        .padding(.horizontal, 12)
        .padding(.bottom, 2)
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tab
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
    @Previewable @State var tab: AppTab = .focus
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
