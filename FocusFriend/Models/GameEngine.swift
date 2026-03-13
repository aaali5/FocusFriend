import Foundation
import SwiftUI

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

    // MARK: - Actions

    func completeFocusSession(minutes: Int) {
        guard minutes > 0 else { return }
        let mins = min(minutes, maxTimerMinutes)

        let multiplier = GameEngine.streakMultiplier(state.streakDays)
        let xpPerMin = GameEngine.xpPerMinute(level: state.level)
        let xpEarned = Int(floor(Double(mins * xpPerMin) * multiplier))
        let bossDamage = mins

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
        let newXP = min(state.xp + xpEarned, maxXP)
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
        save()
    }

    // MARK: - Quest Progress

    private func updateQuestProgress(sessionMinutes: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        var xpBonus = 0

        // daily-1: Morning Focus
        if state.questCompleted["daily-1"] != true && sessionMinutes >= 25 && hour < 10 {
            state.questProgress["daily-1"] = 1
            state.questCompleted["daily-1"] = true
            xpBonus += quests.first(where: { $0.id == "daily-1" })?.xpReward ?? 0
        }

        // daily-2: Deep Dive
        if state.questCompleted["daily-2"] != true && sessionMinutes >= 60 {
            state.questProgress["daily-2"] = 1
            state.questCompleted["daily-2"] = true
            xpBonus += quests.first(where: { $0.id == "daily-2" })?.xpReward ?? 0
        }

        // daily-3: Triple Threat
        state.questProgress["daily-3"] = (state.questProgress["daily-3"] ?? 0) + 1
        if state.questCompleted["daily-3"] != true && (state.questProgress["daily-3"] ?? 0) >= 3 {
            state.questCompleted["daily-3"] = true
            xpBonus += quests.first(where: { $0.id == "daily-3" })?.xpReward ?? 0
        }

        // weekly-1: Marathon Week
        let weeklyMinutes = state.weeklyFocusMinutes.reduce(0, +)
        let weeklyHours = Double(weeklyMinutes) / 60.0
        state.questProgress["weekly-1"] = Double(round(weeklyHours * 10) / 10)
        if state.questCompleted["weekly-1"] != true && weeklyHours >= 10 {
            state.questCompleted["weekly-1"] = true
            xpBonus += quests.first(where: { $0.id == "weekly-1" })?.xpReward ?? 0
        }

        // weekly-2: Consistency Crown
        let last7 = state.focusHistory.suffix(7)
        let focusDays = last7.filter { $0.minutes > 0 }.count
        state.questProgress["weekly-2"] = Double(focusDays)
        if state.questCompleted["weekly-2"] != true && focusDays >= 7 {
            state.questCompleted["weekly-2"] = true
            xpBonus += quests.first(where: { $0.id == "weekly-2" })?.xpReward ?? 0
        }

        // epic-1: The Hundred
        state.questProgress["epic-1"] = Double(state.totalSessions)
        if state.questCompleted["epic-1"] != true && state.totalSessions >= 100 {
            state.questCompleted["epic-1"] = true
            xpBonus += quests.first(where: { $0.id == "epic-1" })?.xpReward ?? 0
        }

        // epic-2: Iron Will
        state.questProgress["epic-2"] = Double(state.streakDays)
        if state.questCompleted["epic-2"] != true && state.streakDays >= 30 {
            state.questCompleted["epic-2"] = true
            xpBonus += quests.first(where: { $0.id == "epic-2" })?.xpReward ?? 0
        }

        // epic-3: Time Lord
        let totalHours = Double(state.totalFocusMinutes) / 60.0
        state.questProgress["epic-3"] = Double(round(totalHours * 10) / 10)
        if state.questCompleted["epic-3"] != true && totalHours >= 500 {
            state.questCompleted["epic-3"] = true
            xpBonus += quests.first(where: { $0.id == "epic-3" })?.xpReward ?? 0
        }

        // Award quest bonus XP
        if xpBonus > 0 {
            state.xp = min(state.xp + xpBonus, maxXP)
            state.level = min(GameEngine.levelFromXP(state.xp), maxLevel)
        }
    }

    // MARK: - Daily Reset

    private func checkDailyReset(_ state: GameState) -> GameState {
        var s = state
        let today = todayString()
        guard s.lastDailyReset != today else { return s }

        for quest in quests where quest.category == .daily {
            s.questProgress[quest.id] = 0
            s.questCompleted[quest.id] = false
        }
        s.lastDailyReset = today
        return s
    }

    // MARK: - Default State

    static func defaultState() -> GameState {
        let today = todayString()
        var focusHistory: [FocusDay] = []
        let cal = Calendar.current
        for i in stride(from: 29, through: 0, by: -1) {
            if let date = cal.date(byAdding: .day, value: -i, to: Date()) {
                let dateStr = dateFormatter.string(from: date)
                let minutes = i == 0 ? 0 : (Double.random(in: 0...1) > 0.3 ? Int.random(in: 15...104) : 0)
                focusHistory.append(FocusDay(date: dateStr, minutes: minutes))
            }
        }
        let weeklyFocusMinutes = focusHistory.suffix(7).map(\.minutes)

        return GameState(
            xp: 2450, level: 8, skillPoints: 3,
            streakDays: 5, streakShields: 0,
            lastFocusDate: today, lastDailyReset: today,
            totalFocusMinutes: 1240, totalSessions: 47,
            bossHP: 680, bossMaxHP: 1200,
            currentBossIndex: 0, bossDamageThisWeek: 520, bossDefeats: 3,
            questProgress: [
                "daily-1": 1, "daily-2": 0, "daily-3": 0,
                "weekly-1": 6.5, "weekly-2": 5,
                "epic-1": 47, "epic-2": 5, "epic-3": 20.7
            ],
            questCompleted: ["daily-1": true],
            skills: ["endurance-1": true, "endurance-2": true, "consistency-1": true],
            focusHistory: focusHistory,
            weeklyFocusMinutes: weeklyFocusMinutes,
            bestStreak: 12
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
