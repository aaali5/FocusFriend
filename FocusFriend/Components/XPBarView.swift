import SwiftUI

// MARK: - XP Bar View

struct XPBarView: View {
    let current: Int
    let total: Int
    let barColor: Color

    @State private var shimmerOffset: CGFloat = -1.0
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let barHeight = geometry.size.height

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.1))

                // Filled portion
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                barColor,
                                barColor.opacity(0.8),
                                barColor,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(barHeight, barWidth * animatedProgress))

                // Shimmer overlay
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: barWidth * 0.3)
                    .offset(x: shimmerOffset * barWidth)
                    .mask(
                        Capsule()
                            .frame(width: max(barHeight, barWidth * animatedProgress))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )

                // Border
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
            withAnimation(
                .linear(duration: 2.0)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.2
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: total) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        XPBarView(current: 65, total: 100, barColor: Color(hex: "#fbbf24"))
            .frame(height: 16)

        XPBarView(current: 30, total: 100, barColor: Color(hex: "#f97316"))
            .frame(height: 12)

        XPBarView(current: 100, total: 100, barColor: Color(hex: "#7c3aed"))
            .frame(height: 20)
    }
    .padding()
    .background(Color(hex: "#0f172a"))
}
