import SwiftUI

struct FoxView: View {
    let stage: EvolutionStage
    var size: CGFloat = 200
    var isAnimating: Bool = true

    @State private var bobOffset: CGFloat = 0
    @State private var tailPhases: [Double] = []
    @State private var glowPulse: Double = 0.6

    private var foxColor: Color { Color(hex: stage.color) }

    var body: some View {
        ZStack {
            // Glow aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            foxColor.opacity(glowPulse * 0.5),
                            foxColor.opacity(glowPulse * 0.2),
                            .clear,
                        ],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)

            // Fox canvas
            Canvas { context, canvasSize in
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2
                let scale = size / 200.0

                // -- Tails --
                let tailCount = stage.tails
                let phases = tailPhases.isEmpty
                    ? Array(repeating: 0.0, count: tailCount)
                    : tailPhases

                for i in 0..<tailCount {
                    let spreadAngle: Double
                    if tailCount == 1 {
                        spreadAngle = 0
                    } else {
                        let range = min(Double(tailCount - 1) * 18.0, 120.0)
                        spreadAngle = -range / 2 + range * Double(i) / Double(tailCount - 1)
                    }

                    let phase = phases.indices.contains(i) ? phases[i] : 0
                    let sway = sin(phase) * 12.0 * scale

                    let tailBaseX = cx + CGFloat(spreadAngle * 0.3) * scale
                    let tailBaseY = cy + 30 * scale

                    var tailPath = Path()
                    tailPath.move(to: CGPoint(x: tailBaseX - 8 * scale, y: tailBaseY))

                    let cp1 = CGPoint(
                        x: tailBaseX + CGFloat(sway) - CGFloat(spreadAngle * 0.5) * scale,
                        y: tailBaseY + 20 * scale
                    )
                    let cp2 = CGPoint(
                        x: tailBaseX + CGFloat(spreadAngle * 0.8) * scale + CGFloat(sway) * 1.5,
                        y: tailBaseY + 50 * scale
                    )
                    let tipPoint = CGPoint(
                        x: tailBaseX + CGFloat(spreadAngle * 1.0) * scale + CGFloat(sway) * 2,
                        y: tailBaseY + 65 * scale
                    )

                    tailPath.addCurve(to: tipPoint, control1: cp1, control2: cp2)

                    let cp3 = CGPoint(
                        x: tailBaseX + CGFloat(spreadAngle * 0.8) * scale + CGFloat(sway) * 1.5 + 6 * scale,
                        y: tailBaseY + 50 * scale
                    )
                    let cp4 = CGPoint(
                        x: tailBaseX + CGFloat(sway) - CGFloat(spreadAngle * 0.5) * scale + 6 * scale,
                        y: tailBaseY + 20 * scale
                    )

                    tailPath.addCurve(
                        to: CGPoint(x: tailBaseX + 8 * scale, y: tailBaseY),
                        control1: cp3,
                        control2: cp4
                    )
                    tailPath.closeSubpath()

                    let tailGradient = Gradient(colors: [
                        stageColor(for: stage),
                        stageColor(for: stage).opacity(0.6),
                        .white.opacity(0.9),
                    ])
                    context.fill(
                        tailPath,
                        with: .linearGradient(
                            tailGradient,
                            startPoint: CGPoint(x: tailBaseX, y: tailBaseY),
                            endPoint: tipPoint
                        )
                    )
                }

                // -- Body --
                let bodyRect = CGRect(
                    x: cx - 38 * scale,
                    y: cy - 30 * scale,
                    width: 76 * scale,
                    height: 70 * scale
                )
                let bodyPath = RoundedRectangle(cornerRadius: 28 * scale)
                    .path(in: bodyRect)

                let bodyGradient = Gradient(colors: [
                    stageColor(for: stage),
                    stageColor(for: stage).opacity(0.7),
                ])
                context.fill(
                    bodyPath,
                    with: .linearGradient(
                        bodyGradient,
                        startPoint: CGPoint(x: cx, y: cy - 30 * scale),
                        endPoint: CGPoint(x: cx, y: cy + 40 * scale)
                    )
                )

                // -- Belly patch --
                let bellyRect = CGRect(
                    x: cx - 20 * scale,
                    y: cy - 5 * scale,
                    width: 40 * scale,
                    height: 32 * scale
                )
                let bellyPath = Ellipse().path(in: bellyRect)
                context.fill(bellyPath, with: .color(.white.opacity(0.25)))

                // -- Ears --
                for side in [-1.0, 1.0] {
                    var earPath = Path()
                    let earBaseX = cx + CGFloat(side) * 22 * scale
                    let earBaseY = cy - 28 * scale
                    earPath.move(to: CGPoint(x: earBaseX - 12 * scale, y: earBaseY))
                    earPath.addLine(to: CGPoint(x: earBaseX, y: earBaseY - 28 * scale))
                    earPath.addLine(to: CGPoint(x: earBaseX + 12 * scale, y: earBaseY))
                    earPath.closeSubpath()

                    context.fill(earPath, with: .color(stageColor(for: stage)))

                    // Inner ear
                    var innerEar = Path()
                    innerEar.move(to: CGPoint(x: earBaseX - 6 * scale, y: earBaseY - 4 * scale))
                    innerEar.addLine(to: CGPoint(x: earBaseX, y: earBaseY - 22 * scale))
                    innerEar.addLine(to: CGPoint(x: earBaseX + 6 * scale, y: earBaseY - 4 * scale))
                    innerEar.closeSubpath()

                    context.fill(innerEar, with: .color(stageColor(for: stage).opacity(0.5)))
                }

                // -- Eyes --
                for side in [-1.0, 1.0] {
                    let eyeX = cx + CGFloat(side) * 16 * scale
                    let eyeY = cy - 10 * scale

                    // White outer
                    let eyeRect = CGRect(
                        x: eyeX - 8 * scale,
                        y: eyeY - 8 * scale,
                        width: 16 * scale,
                        height: 16 * scale
                    )
                    context.fill(Ellipse().path(in: eyeRect), with: .color(.white))

                    // Dark pupil
                    let pupilRect = CGRect(
                        x: eyeX - 4 * scale + CGFloat(side) * 1.5 * scale,
                        y: eyeY - 4 * scale,
                        width: 8 * scale,
                        height: 9 * scale
                    )
                    context.fill(Ellipse().path(in: pupilRect), with: .color(Color(hex: "#1e293b")))

                    // Highlight
                    let highlightRect = CGRect(
                        x: eyeX - 1.5 * scale + CGFloat(side) * 2 * scale,
                        y: eyeY - 5 * scale,
                        width: 4 * scale,
                        height: 4 * scale
                    )
                    context.fill(Ellipse().path(in: highlightRect), with: .color(.white.opacity(0.9)))
                }

                // -- Nose --
                let noseSize = 5 * scale
                var nosePath = Path()
                nosePath.move(to: CGPoint(x: cx, y: cy + 2 * scale))
                nosePath.addLine(to: CGPoint(x: cx - noseSize, y: cy - 3 * scale))
                nosePath.addLine(to: CGPoint(x: cx + noseSize, y: cy - 3 * scale))
                nosePath.closeSubpath()
                context.fill(nosePath, with: .color(Color(hex: "#1e293b")))

                // -- Mouth --
                var mouthPath = Path()
                mouthPath.move(to: CGPoint(x: cx, y: cy + 2 * scale))
                mouthPath.addLine(to: CGPoint(x: cx - 6 * scale, y: cy + 8 * scale))
                mouthPath.move(to: CGPoint(x: cx, y: cy + 2 * scale))
                mouthPath.addLine(to: CGPoint(x: cx + 6 * scale, y: cy + 8 * scale))
                context.stroke(
                    mouthPath,
                    with: .color(Color(hex: "#1e293b").opacity(0.6)),
                    lineWidth: 1.5 * scale
                )

            } // end Canvas
            .frame(width: size, height: size)
            .offset(y: bobOffset)
        }
        .onAppear {
            // Initialize tail phases
            tailPhases = (0..<stage.tails).map { i in
                Double(i) * (.pi / Double(max(stage.tails, 1)) * 0.8)
            }

            guard isAnimating else { return }

            // Floating bob animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                bobOffset = -8
            }

            // Glow pulse
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = 1.0
            }

            // Tail sway timer
            startTailAnimation()
        }
    }

    // MARK: - Helpers

    private func stageColor(for stage: EvolutionStage) -> Color {
        Color(hex: stage.color)
    }

    private func startTailAnimation() {
        guard isAnimating else { return }

        // Use a display-link style timer for smooth tail movement
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { timer in
            guard isAnimating else {
                timer.invalidate()
                return
            }
            var updated = tailPhases
            for i in updated.indices {
                let speed = 2.5 + Double(i) * 0.3
                updated[i] += speed * (1.0 / 30.0)
            }
            tailPhases = updated
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        FoxView(
            stage: evolutionStages[0],
            size: 180,
            isAnimating: true
        )

        FoxView(
            stage: evolutionStages[4],
            size: 220,
            isAnimating: true
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#0f172a"))
}
