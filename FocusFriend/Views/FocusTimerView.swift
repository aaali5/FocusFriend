import SwiftUI

// MARK: - Timer State Machine

private enum TimerPhase {
    case idle
    case running
    case paused
    case completed
}

struct FocusTimerView: View {
    @EnvironmentObject private var engine: GameEngine
    @State private var phase: TimerPhase = .idle
    @State private var selectedMinutes: Int = 25
    @State private var remainingSeconds: Int = 25 * 60
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var timerCancellable: (any Cancellable)?
    @State private var earnedXP: Int = 0
    @State private var pulseRing: Bool = false
    @State private var showCompletionGlow: Bool = false
    @State private var foxBounce: Bool = false

    // Presets
    private let presets: [Int] = [15, 25, 45, 60]

    // Computed
    private var totalSeconds: Int { selectedMinutes * 60 }
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }
    private var elapsedMinutes: Int {
        max(0, (totalSeconds - remainingSeconds) / 60)
    }
    private var countdownText: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    private var potentialXP: Int {
        let elapsed = Double(totalSeconds - remainingSeconds) / 60.0
        return Int(elapsed * Double(GameEngine.xpPerMinute(level: engine.state.level)) * GameEngine.streakMultiplier(engine.state.streakDays))
    }
    private var estimatedTotalXP: Int {
        Int(Double(selectedMinutes * GameEngine.xpPerMinute(level: engine.state.level)) * GameEngine.streakMultiplier(engine.state.streakDays))
    }
    private var estimatedBossDamage: Int {
        selectedMinutes
    }

    private var stageColor: Color {
        Color(hex: GameEngine.evolutionStage(for: engine.state.level).color)
    }

    var body: some View {
        let stage = GameEngine.evolutionStage(for: engine.state.level)

        ScrollView {
            VStack(spacing: 28) {
                // MARK: - Header
                headerSection(stage: stage)

                // MARK: - Timer Ring
                timerRingSection(stage: stage)

                // MARK: - Duration Presets
                if phase == .idle {
                    presetButtons
                }

                // MARK: - Live XP Counter (during focus)
                if phase == .running || phase == .paused {
                    liveXPCounter
                }

                // MARK: - Controls
                controlButtons

                // MARK: - Session Info Cards
                if phase != .completed {
                    sessionInfoCards(stage: stage)
                }

                // MARK: - Completion Summary
                if phase == .completed {
                    completionSummary
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Color.navyBg.ignoresSafeArea())
        .onReceive(timer) { _ in
            guard phase == .running else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
            if remainingSeconds <= 0 {
                finishSession()
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(stage: EvolutionStage) -> some View {
        VStack(spacing: 4) {
            Text(phase == .completed ? "Session Complete!" : "Focus Timer")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(stage.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(stageColor.opacity(0.8))
        }
        .padding(.top, 4)
    }

    // MARK: - Timer Ring

    @ViewBuilder
    private func timerRingSection(stage: EvolutionStage) -> some View {
        let diameter: CGFloat = 280
        let lineWidth: CGFloat = 14

        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            stageColor.opacity(0.6),
                            stageColor,
                            Color.xpGold,
                            stageColor
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Glow behind ring when active
            if phase == .running {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        stageColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: lineWidth + 12, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8)
                    .animation(.easeInOut(duration: 0.6), value: progress)
            }

            // Pulse ring when running
            if phase == .running {
                Circle()
                    .stroke(stageColor.opacity(pulseRing ? 0 : 0.25), lineWidth: 2)
                    .frame(
                        width: diameter + (pulseRing ? 40 : 0),
                        height: diameter + (pulseRing ? 40 : 0)
                    )
                    .animation(
                        .easeOut(duration: 2).repeatForever(autoreverses: false),
                        value: pulseRing
                    )
            }

            // Completion burst
            if phase == .completed && showCompletionGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [stageColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: 180
                        )
                    )
                    .frame(width: diameter + 80, height: diameter + 80)
                    .transition(.opacity)
            }

            // Center content
            VStack(spacing: 8) {
                FoxView(
                    stage: stage,
                    size: 100,
                    isAnimating: phase == .running
                )

                Text(countdownText)
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        phase == .running
                            ? Color.xpGold
                            : Color.white.opacity(0.9)
                    )
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: remainingSeconds)

                if phase == .idle {
                    Text("\(selectedMinutes) min session")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Preset Buttons

    private var presetButtons: some View {
        HStack(spacing: 12) {
            ForEach(presets, id: \.self) { mins in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedMinutes = mins
                        remainingSeconds = mins * 60
                    }
                } label: {
                    Text("\(mins)m")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            selectedMinutes == mins ? Color.navyBg : .white.opacity(0.7)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedMinutes == mins
                                        ? Color.xpGold
                                        : Color.white.opacity(0.1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Live XP Counter

    private var liveXPCounter: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.xpGold)
                .symbolEffect(.pulse, options: .repeating, value: phase == .running)

            Text("+\(potentialXP) XP")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.xpGold)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: potentialXP)

            Text("earned so far")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(Color.xpGold.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.xpGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 16) {
            switch phase {
            case .idle:
                // Start
                timerButton(
                    title: "Start Focus",
                    icon: "play.fill",
                    color: Color.xpGold,
                    textColor: Color.navyBg,
                    isWide: true
                ) {
                    startTimer()
                }

            case .running:
                // Pause
                timerButton(
                    title: "Pause",
                    icon: "pause.fill",
                    color: .white.opacity(0.15),
                    textColor: .white
                ) {
                    pauseTimer()
                }
                // Complete Early
                timerButton(
                    title: "Complete",
                    icon: "checkmark.circle.fill",
                    color: Color(hex: "#22c55e"),
                    textColor: .white
                ) {
                    finishSession()
                }

            case .paused:
                // Resume
                timerButton(
                    title: "Resume",
                    icon: "play.fill",
                    color: Color.xpGold,
                    textColor: Color.navyBg
                ) {
                    resumeTimer()
                }
                // Reset
                timerButton(
                    title: "Reset",
                    icon: "arrow.counterclockwise",
                    color: Color.bossRed.opacity(0.2),
                    textColor: Color.bossRed
                ) {
                    resetTimer()
                }

            case .completed:
                timerButton(
                    title: "New Session",
                    icon: "arrow.counterclockwise",
                    color: stageColor,
                    textColor: .white,
                    isWide: true
                ) {
                    resetTimer()
                }
            }
        }
    }

    @ViewBuilder
    private func timerButton(
        title: String,
        icon: String,
        color: Color,
        textColor: Color,
        isWide: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: isWide ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, isWide ? 0 : 24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Info Cards

    @ViewBuilder
    private func sessionInfoCards(stage: EvolutionStage) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            infoCard(
                icon: "sparkles",
                title: "XP Rate",
                value: "\(GameEngine.xpPerMinute(level: engine.state.level))/min",
                accent: Color.xpGold
            )

            infoCard(
                icon: "flame.fill",
                title: "Streak x\(String(format: "%.1f", GameEngine.streakMultiplier(engine.state.streakDays)))",
                value: "\(engine.state.streakDays) days",
                accent: Color.foxOrange
            )

            infoCard(
                icon: "bolt.fill",
                title: "Est. Total XP",
                value: "+\(estimatedTotalXP)",
                accent: stageColor
            )

            infoCard(
                icon: "shield.lefthalf.filled",
                title: "Boss Damage",
                value: "\(estimatedBossDamage) HP",
                accent: Color.bossRed
            )
        }
    }

    @ViewBuilder
    private func infoCard(
        icon: String,
        title: String,
        value: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accent.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Completion Summary

    private var completionSummary: some View {
        VStack(spacing: 16) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(Color.xpGold.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.xpGold)
            }

            Text("Excellent Focus!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Stats
            VStack(spacing: 10) {
                completionRow(label: "Duration", value: "\(elapsedMinutes) min")
                completionRow(label: "XP Earned", value: "+\(earnedXP)", highlight: true)
                completionRow(label: "Boss Damage", value: "\(elapsedMinutes) HP")
                completionRow(
                    label: "Streak Multiplier",
                    value: "x\(String(format: "%.1f", GameEngine.streakMultiplier(engine.state.streakDays)))"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    @ViewBuilder
    private func completionRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? Color.xpGold : .white)
        }
    }

    // MARK: - Timer Actions

    private func startTimer() {
        remainingSeconds = selectedMinutes * 60
        phase = .running
        startPublisher()
        pulseRing = true

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            foxBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            foxBounce = false
        }
    }

    private func pauseTimer() {
        phase = .paused
        stopPublisher()
        pulseRing = false
    }

    private func resumeTimer() {
        phase = .running
        startPublisher()
        pulseRing = true
    }

    private func resetTimer() {
        phase = .idle
        stopPublisher()
        remainingSeconds = selectedMinutes * 60
        earnedXP = 0
        pulseRing = false
        showCompletionGlow = false
    }

    private func finishSession() {
        stopPublisher()
        pulseRing = false

        let minutesFocused = max(1, (totalSeconds - remainingSeconds + 30) / 60)
        let multiplier = GameEngine.streakMultiplier(engine.state.streakDays)
        let xpPerMin = GameEngine.xpPerMinute(level: engine.state.level)
        earnedXP = Int(Double(minutesFocused * xpPerMin) * multiplier)

        engine.completeFocusSession(minutes: minutesFocused)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            phase = .completed
            showCompletionGlow = true
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Secondary impact for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }

    // MARK: - Publisher Management

    private func startPublisher() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
        timerCancellable = timer.connect()
    }

    private func stopPublisher() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

#Preview {
    FocusTimerView()
        .environmentObject(GameEngine())
}
