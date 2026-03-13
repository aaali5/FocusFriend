import Foundation
import SwiftUI
import UserNotifications

// MARK: - Bounds Constants

private let maxXP = 10_000_000
private let maxLevel = 100
private let maxSkillPoints = 50
private let maxStreakDays = 3650
private let maxStreakShields = 100
private let maxFocusMinutes = 1_000_000
private let maxSessions = 100_000
private let maxBossHP = 100_000
private let maxBossDefeats = 10_000
private let maxTimerMinutes = 180
private let maxDailyFocusMinutes = 1440

// MARK: - Game Engine

@MainActor
class GameEngine: ObservableObject {
    @Published var state: GameState

    init() {
        self.state = Persistence.load() ?? GameEngine.defaultState()
        self.state = checkDailyReset(self.state)
        save()
    }

    // MARK: - XP & Leveling

    static func xpForLevel(_ level: Int) -> Int {
        Int(floor(100.0 * pow(1.15, Double(level - 1))))
    }

    static func totalXPForLevel(_ level: Int) -> Int {
        (1...level).reduce(0) { $0 + xpForLevel($1) }
    }

    static func levelFromXP(_ totalXP: Int) -> Int {
        var level = 1
        var accumulated = 0
        while level < 100 {
            let needed = xpForLevel(level + 1)
            if accumulated + needed > totalXP { break }
            accumulated += needed
            level += 1
        }
        return level
    }

    static func xpProgress(totalXP: Int) -> (current: Int, needed: Int, percentage: Double) {
        let level = levelFromXP(totalXP)
        let xpForCurrent = totalXPForLevel(level)
        let xpForNext = xpForLevel(level + 1)
        let current = totalXP - xpForCurrent
        return (current, xpForNext, min(Double(current) / Double(xpForNext) * 100, 100))
    }

    static func streakMultiplier(_ streakDays: Int) -> Double {
        if streakDays >= 30 { return 5 }
        if streakDays >= 14 { return 3 }
        if streakDays >= 7 { return 2 }
        if streakDays >= 3 { return 1.5 }
        return 1
    }

    static func xpPerMinute(level: Int) -> Int {
        10 + level / 10
    }

    static func evolutionStage(for level: Int) -> EvolutionStage {
        for stage in evolutionStages.reversed() {
            if level >= stage.minLevel { return stage }
        }
        return evolutionStages[0]
    }

    // MARK: - Skill-Aware Instance Methods

    /// Checks whether a given skill is unlocked in the current state.
    private func hasSkill(_ id: String) -> Bool {
        state.skills[id] == true
    }

    /// Instance-level XP per minute that accounts for endurance-1 ("Iron Focus": +5 XP/min).
    func effectiveXPPerMinute() -> Int {
        var base = GameEngine.xpPerMinute(level: state.level)
        if hasSkill("endurance-1") { base += 5 }
        return base
    }

    /// Instance-level streak multiplier that accounts for consistency-4 ("Unbreakable": higher caps).
    func effectiveStreakMultiplier() -> Double {
        let days = state.streakDays
        if hasSkill("consistency-4") {
            if days >= 60 { return 8 }
            if days >= 45 { return 6 }
        }
        // Fall through to base tiers
        return GameEngine.streakMultiplier(days)
    }

    /// Returns available timer presets based on unlocked skills.
    /// Base: [15, 25, 45, 60]. endurance-2 adds 90, endurance-4 adds 120.
    static func timerPresets(skills: [String: Bool]) -> [Int] {
        var presets = [15, 25, 45, 60]
        if skills["endurance-2"] == true { presets.append(90) }
        if skills["endurance-4"] == true { presets.append(120) }
        return presets
    }

    // MARK: - Actions

    /// Original signature preserved for backward compatibility.
    func completeFocusSession(minutes: Int) {
        completeFocusSession(minutes: minutes, completedFull: false, label: nil)
    }

    /// Complete a focus session with skill bonuses applied.
    /// - Parameters:
    ///   - minutes: Total minutes focused.
    ///   - completedFull: Whether the timer ran to zero (not completed early).
    ///   - label: Optional label describing the session.
    func completeFocusSession(minutes: Int, completedFull: Bool, label: String? = nil) {
        guard minutes > 0 else { return }
        let mins = min(minutes, maxTimerMinutes)

        let streakMult = effectiveStreakMultiplier()
        let xpPerMin = effectiveXPPerMinute()

        // --- Base XP calculation (with intensity-2 "Flow State") ---
        var baseXP: Double
        if hasSkill("intensity-2") && mins >= 20 {
            // First 20 minutes at normal rate, remaining minutes at +25%
            let normalMinutes = 20
            let bonusMinutes = mins - 20
            baseXP = Double(normalMinutes * xpPerMin) + Double(bonusMinutes * xpPerMin) * 1.25
        } else {
            baseXP = Double(mins * xpPerMin)
        }

        // --- Apply streak multiplier ---
        var xpEarned = baseXP * streakMult

        // --- endurance-3 "Second Wind": 2x XP for the last 10 min if session > 10 min ---
        if hasSkill("endurance-3") && mins > 10 {
            let bonusMinutes = min(mins, 10)
            xpEarned += Double(bonusMinutes) * Double(xpPerMin) * streakMult
        }

        // --- consistency-1 "Routine Power": Morning sessions (before 10am) give +25% XP ---
        let hour = Calendar.current.component(.hour, from: Date())
        if hasSkill("consistency-1") && hour < 10 {
            xpEarned *= 1.25
        }

        // --- intensity-1 "Deep Focus": +10% XP for uninterrupted (full) sessions ---
        if hasSkill("intensity-1") && completedFull {
            xpEarned *= 1.10
        }

        // --- intensity-4 "Zen Master": +50% to final XP (approximates multiplicative stacking) ---
        if hasSkill("intensity-4") {
            xpEarned *= 1.50
        }

        let finalXP = Int(floor(xpEarned))

        // --- Boss damage calculation ---
        var bossDamage = mins

        // endurance-4 "Marathon Master": +50% boss damage from sessions over 45 min
        if hasSkill("endurance-4") && mins > 45 {
            bossDamage = Int(floor(Double(bossDamage) * 1.5))
        }

        // intensity-3 "Critical Hit": 10% chance to deal 3x boss damage
        if hasSkill("intensity-3") && Int.random(in: 1...10) == 1 {
            bossDamage *= 3
        }

        let today = todayString()
        let isNewDay = state.lastFocusDate != today

        // Streak logic
        var newStreakDays = state.streakDays
        var usedShield = false
        if isNewDay {
            if let lastDate = state.lastFocusDate {
                let diffDays = daysBetween(lastDate, today)
                if diffDays == 1 {
                    newStreakDays += 1
                } else if diffDays > 1 {
                    if state.streakShields > 0 {
                        newStreakDays += 1
                        usedShield = true
                    } else {
                        newStreakDays = 1
                    }
                }
            } else {
                newStreakDays = 1
            }
        }

        // Add XP
        let newXP = min(state.xp + finalXP, maxXP)
        let newLevel = min(GameEngine.levelFromXP(newXP), maxLevel)
        let skillPointsGained = max(0, newLevel - state.level)

        state.xp = newXP
        state.level = newLevel
        state.skillPoints = min(state.skillPoints + skillPointsGained, maxSkillPoints)
        state.totalFocusMinutes += mins
        state.totalSessions += 1
        state.bossHP = max(0, state.bossHP - bossDamage)
        state.bossDamageThisWeek += bossDamage
        state.lastFocusDate = today
        state.streakDays = newStreakDays
        if usedShield { state.streakShields -= 1 }
        state.bestStreak = max(state.bestStreak, newStreakDays)

        // consistency-2 "Streak Shield": Earn a streak shield every 5 streak days
        if hasSkill("consistency-2") && newStreakDays > 0 && newStreakDays % 5 == 0 && isNewDay {
            state.streakShields = min(state.streakShields + 1, maxStreakShields)
        }

        // Update focus history
        if let idx = state.focusHistory.firstIndex(where: { $0.date == today }) {
            state.focusHistory[idx].minutes += mins
        } else {
            state.focusHistory.append(FocusDay(date: today, minutes: mins))
        }
        state.weeklyFocusMinutes = state.focusHistory.suffix(7).map(\.minutes)

        // Check boss defeat
        if state.bossHP <= 0 {
            state.bossDefeats += 1
            state.currentBossIndex = (state.currentBossIndex + 1) % bosses.count
            state.bossHP = 1200 + state.bossDefeats * 200
            state.bossMaxHP = state.bossHP
            state.bossDamageThisWeek = 0
        }

        // Update quests
        updateQuestProgress(sessionMinutes: mins)

        // Record session with label
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let session = FocusSession(
            date: today,
            startTime: timeFormatter.string(from: Date()),
            minutes: mins,
            label: label,
            xpEarned: finalXP
        )
        state.recentSessions.append(session)
        if state.recentSessions.count > 50 {
            state.recentSessions.removeFirst(state.recentSessions.count - 50)
        }

        // Track recent labels for quick-pick suggestions
        if let label = label, !label.isEmpty {
            state.recentLabels.removeAll { $0 == label }
            state.recentLabels.insert(label, at: 0)
            if state.recentLabels.count > 10 {
                state.recentLabels = Array(state.recentLabels.prefix(10))
            }
        }

        // Schedule boss taunt if HP is low
        let hpPercent = state.bossMaxHP > 0 ? (state.bossHP * 100 / state.bossMaxHP) : 0
        let currentBoss = bosses[state.currentBossIndex % bosses.count]
        NotificationManager.scheduleBossTaunt(bossName: currentBoss.name, hpPercent: hpPercent)

        // Update streak reminder
        NotificationManager.scheduleStreakReminder(streakDays: state.streakDays)

        save()
    }

    func unlockSkill(_ skillId: String) {
        guard state.skillPoints > 0 else { return }
        guard state.skills[skillId] != true else { return }

        if let node = skillTree.first(where: { $0.id == skillId }) {
            if let req = node.requires, state.skills[req] != true { return }
        }

        state.skills[skillId] = true
        state.skillPoints -= 1
        state.weeklySkillsUnlocked += 1
        save()
    }

    // MARK: - Quest Progress

    private func updateQuestProgress(sessionMinutes: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        let today = todayString()
        var xpBonus = 0

        // Helper: today's accumulated minutes from focus history
        let todayMinutes = state.focusHistory.first(where: { $0.date == today })?.minutes ?? 0

        // Helper: yesterday's accumulated minutes
        let yesterdayMinutes: Int = {
            guard let d = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
            let yStr = GameEngine.dateFormatter.string(from: d)
            return state.focusHistory.first(where: { $0.date == yStr })?.minutes ?? 0
        }()

        // Helper: count of sessions today (from recentSessions)
        let sessionsToday = state.recentSessions.filter { $0.date == today }.count

        // Complete a quest by ID (guard against non-active or already completed)
        func completeQuest(_ id: String) {
            guard state.questCompleted[id] != true else { return }
            guard let quest = quests.first(where: { $0.id == id }) else { return }
            state.questProgress[id] = quest.target
            state.questCompleted[id] = true
            xpBonus += quest.xpReward
        }

        // Track early session for weekly-3
        if hour < 9 {
            state.weeklyEarlySessions += 1
        }

        let activeDailyIds = Set(state.activeDailyQuests)
        let activeWeeklyIds = Set(state.activeWeeklyQuests)

        // ========== DAILY QUESTS ==========

        if activeDailyIds.contains("daily-1") && sessionMinutes >= 25 && hour < 10 {
            completeQuest("daily-1")
        }
        if activeDailyIds.contains("daily-2") && sessionMinutes >= 60 {
            completeQuest("daily-2")
        }
        if activeDailyIds.contains("daily-3") {
            state.questProgress["daily-3"] = Double(sessionsToday)
            if sessionsToday >= 3 { completeQuest("daily-3") }
        }
        if activeDailyIds.contains("daily-4") && hour < 8 {
            completeQuest("daily-4")
        }
        if activeDailyIds.contains("daily-5") {
            state.questProgress["daily-5"] = Double(todayMinutes)
            if todayMinutes >= 60 { completeQuest("daily-5") }
        }
        if activeDailyIds.contains("daily-6") && sessionMinutes >= 15 {
            completeQuest("daily-6")
        }
        if activeDailyIds.contains("daily-7") {
            state.questProgress["daily-7"] = Double(sessionsToday)
            if sessionsToday >= 2 { completeQuest("daily-7") }
        }
        if activeDailyIds.contains("daily-8") && hour >= 20 {
            completeQuest("daily-8")
        }
        if activeDailyIds.contains("daily-9") && sessionMinutes >= 30 {
            completeQuest("daily-9")
        }
        if activeDailyIds.contains("daily-10") && hour >= 13 && hour < 17 {
            completeQuest("daily-10")
        }
        if activeDailyIds.contains("daily-11") {
            state.questProgress["daily-11"] = Double(todayMinutes)
            if todayMinutes >= 90 { completeQuest("daily-11") }
        }
        if activeDailyIds.contains("daily-12") {
            state.questProgress["daily-12"] = Double(sessionsToday)
            if sessionsToday >= 4 { completeQuest("daily-12") }
        }
        if activeDailyIds.contains("daily-13") {
            state.questProgress["daily-13"] = todayMinutes > yesterdayMinutes ? 1 : 0
            if todayMinutes > yesterdayMinutes { completeQuest("daily-13") }
        }
        if activeDailyIds.contains("daily-14") && sessionMinutes >= 45 && hour < 12 {
            completeQuest("daily-14")
        }
        if activeDailyIds.contains("daily-15") && sessionMinutes >= 20 {
            completeQuest("daily-15")
        }

        // ========== WEEKLY QUESTS ==========

        if activeWeeklyIds.contains("weekly-1") {
            let wMin = state.weeklyFocusMinutes.reduce(0, +)
            let wHrs = Double(wMin) / 60.0
            state.questProgress["weekly-1"] = Double(round(wHrs * 10) / 10)
            if wHrs >= 10 { completeQuest("weekly-1") }
        }
        if activeWeeklyIds.contains("weekly-2") {
            let last7 = state.focusHistory.suffix(7)
            let focusDays = last7.filter { $0.minutes > 0 }.count
            state.questProgress["weekly-2"] = Double(focusDays)
            if focusDays >= 7 { completeQuest("weekly-2") }
        }
        if activeWeeklyIds.contains("weekly-3") {
            state.questProgress["weekly-3"] = Double(state.weeklyEarlySessions)
            if state.weeklyEarlySessions >= 3 { completeQuest("weekly-3") }
        }
        if activeWeeklyIds.contains("weekly-4") {
            state.questProgress["weekly-4"] = Double(state.bossDamageThisWeek)
            if state.bossDamageThisWeek >= 200 { completeQuest("weekly-4") }
        }
        if activeWeeklyIds.contains("weekly-5") {
            var consecutive = 0
            let cal = Calendar.current
            var checkDate = Date()
            for _ in 0..<7 {
                let dateStr = GameEngine.dateFormatter.string(from: checkDate)
                if state.focusHistory.contains(where: { $0.date == dateStr && $0.minutes > 0 }) {
                    consecutive += 1
                } else { break }
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
            state.questProgress["weekly-5"] = Double(consecutive)
            if consecutive >= 5 { completeQuest("weekly-5") }
        }
        if activeWeeklyIds.contains("weekly-6") {
            state.questProgress["weekly-6"] = Double(state.weeklySkillsUnlocked)
            if state.weeklySkillsUnlocked >= 2 { completeQuest("weekly-6") }
        }

        // ========== EPIC QUESTS (always active) ==========

        state.questProgress["epic-1"] = Double(state.totalSessions)
        if state.totalSessions >= 100 { completeQuest("epic-1") }

        state.questProgress["epic-2"] = Double(state.streakDays)
        if state.streakDays >= 30 { completeQuest("epic-2") }

        let totalHours = Double(state.totalFocusMinutes) / 60.0
        state.questProgress["epic-3"] = Double(round(totalHours * 10) / 10)
        if totalHours >= 500 { completeQuest("epic-3") }

        // Award quest bonus XP
        if xpBonus > 0 {
            state.xp = min(state.xp + xpBonus, maxXP)
            state.level = min(GameEngine.levelFromXP(state.xp), maxLevel)
        }
    }

    // MARK: - Active Quest Helpers

    /// Returns today's active quests: the selected dailies, selected weeklies, and all epics.
    func activeQuests() -> [Quest] {
        let dailyIds = Set(state.activeDailyQuests)
        let weeklyIds = Set(state.activeWeeklyQuests)
        let activeDailies = quests.filter { $0.category == .daily && dailyIds.contains($0.id) }
        let activeWeeklies = quests.filter { $0.category == .weekly && weeklyIds.contains($0.id) }
        let epics = quests.filter { $0.category == .epic }
        return activeDailies + activeWeeklies + epics
    }

    /// Deterministically selects `count` items from `pool` using a seeded RNG.
    private static func seededSelection<T>(from pool: [T], count: Int, seed: String) -> [T] {
        guard pool.count > count else { return pool }
        var hashValue = seed.utf8.reduce(into: UInt64(5381)) { hash, byte in
            hash = hash &* 33 &+ UInt64(byte)
        }
        var indices = Array(pool.indices)
        for i in stride(from: indices.count - 1, through: 1, by: -1) {
            hashValue = hashValue &* 6364136223846793005 &+ 1442695040888963407
            let j = Int(hashValue % UInt64(i + 1))
            indices.swapAt(i, j)
        }
        return Array(indices.prefix(count)).sorted().map { pool[$0] }
    }

    // MARK: - Daily Reset

    private func checkDailyReset(_ state: GameState) -> GameState {
        var s = state
        let today = todayString()
        let needsDailyReset = s.lastDailyReset != today
        let needsWeeklyReset: Bool = {
            let weekday = Calendar.current.component(.weekday, from: Date())
            guard weekday == 2 else { return s.lastWeeklyReset == nil }
            return s.lastWeeklyReset != today
        }()

        guard needsDailyReset || s.activeDailyQuests.isEmpty || s.activeWeeklyQuests.isEmpty else { return s }

        if needsDailyReset {
            for quest in quests where quest.category == .daily {
                s.questProgress[quest.id] = 0
                s.questCompleted[quest.id] = false
            }

            let dailyPool = quests.filter { $0.category == .daily }
            let selectedDailies = GameEngine.seededSelection(from: dailyPool, count: 3, seed: today)
            s.activeDailyQuests = selectedDailies.map(\.id)

            // consistency-3 "Daily Discipline": Auto-complete 1 daily quest per day
            if s.skills["consistency-3"] == true {
                if let firstIncomplete = selectedDailies.first(where: {
                    s.questCompleted[$0.id] != true
                }) {
                    s.questProgress[firstIncomplete.id] = firstIncomplete.target
                    s.questCompleted[firstIncomplete.id] = true
                    s.xp = min(s.xp + firstIncomplete.xpReward, maxXP)
                    s.level = min(GameEngine.levelFromXP(s.xp), maxLevel)
                }
            }

            s.lastDailyReset = today
        }

        if needsWeeklyReset || s.activeWeeklyQuests.isEmpty {
            for quest in quests where quest.category == .weekly {
                s.questProgress[quest.id] = 0
                s.questCompleted[quest.id] = false
            }
            s.weeklySkillsUnlocked = 0
            s.weeklyEarlySessions = 0

            let cal = Calendar.current
            let weekOfYear = cal.component(.weekOfYear, from: Date())
            let year = cal.component(.yearForWeekOfYear, from: Date())
            let weeklySeed = "\(year)-W\(weekOfYear)"

            let weeklyPool = quests.filter { $0.category == .weekly }
            let selectedWeeklies = GameEngine.seededSelection(from: weeklyPool, count: 2, seed: weeklySeed)
            s.activeWeeklyQuests = selectedWeeklies.map(\.id)
            s.lastWeeklyReset = today
        }

        if s.activeDailyQuests.isEmpty {
            let dailyPool = quests.filter { $0.category == .daily }
            let selectedDailies = GameEngine.seededSelection(from: dailyPool, count: 3, seed: today)
            s.activeDailyQuests = selectedDailies.map(\.id)
        }

        return s
    }

    // MARK: - Default State

    static func defaultState() -> GameState {
        GameState(
            xp: 0, level: 1, skillPoints: 0,
            streakDays: 0, streakShields: 0,
            lastFocusDate: nil, lastDailyReset: todayString(),
            totalFocusMinutes: 0, totalSessions: 0,
            bossHP: 1200, bossMaxHP: 1200,
            currentBossIndex: 0, bossDamageThisWeek: 0, bossDefeats: 0,
            questProgress: [:],
            questCompleted: [:],
            skills: [:],
            focusHistory: [],
            weeklyFocusMinutes: [],
            bestStreak: 0
        )
    }

    // MARK: - Persistence

    func save() {
        Persistence.save(state)
    }

    func reset() {
        state = GameEngine.defaultState()
        save()
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        dateFormatter.string(from: Date())
    }

    private func todayString() -> String {
        GameEngine.dateFormatter.string(from: Date())
    }

    private func daysBetween(_ from: String, _ to: String) -> Int {
        guard let d1 = GameEngine.dateFormatter.date(from: from),
              let d2 = GameEngine.dateFormatter.date(from: to) else { return 0 }
        return Calendar.current.dateComponents([.day], from: d1, to: d2).day ?? 0
    }
}
