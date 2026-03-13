import Foundation

// MARK: - Game State

struct FocusDay: Codable, Identifiable {
    var id: String { date }
    let date: String  // YYYY-MM-DD
    var minutes: Int
}

struct FocusSession: Codable, Identifiable {
    var id: String { "\(date)-\(startTime)" }
    let date: String        // YYYY-MM-DD
    let startTime: String   // HH:mm
    let minutes: Int
    let label: String?
    let xpEarned: Int
}

struct GameState: Codable {
    var xp: Int
    var level: Int
    var skillPoints: Int
    var streakDays: Int
    var streakShields: Int
    var lastFocusDate: String?  // ISO date YYYY-MM-DD
    var lastDailyReset: String?
    var totalFocusMinutes: Int
    var totalSessions: Int
    var bossHP: Int
    var bossMaxHP: Int
    var currentBossIndex: Int
    var bossDamageThisWeek: Int
    var bossDefeats: Int
    var questProgress: [String: Double]
    var questCompleted: [String: Bool]
    var skills: [String: Bool]
    var focusHistory: [FocusDay]
    var weeklyFocusMinutes: [Int]
    var bestStreak: Int
    var recentSessions: [FocusSession]
    var recentLabels: [String]
    var activeDailyQuests: [String]   // IDs of today's 3 selected daily quests
    var activeWeeklyQuests: [String]  // IDs of this week's 2 selected weekly quests
    var lastWeeklyReset: String?      // ISO date YYYY-MM-DD for weekly rotation
    var weeklySkillsUnlocked: Int     // Skills unlocked this week (for weekly-6)
    var weeklyEarlySessions: Int      // Sessions started before 9am this week (for weekly-3)

    // Custom decoder so existing saved states (without the new fields) load safely.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        xp = try c.decode(Int.self, forKey: .xp)
        level = try c.decode(Int.self, forKey: .level)
        skillPoints = try c.decode(Int.self, forKey: .skillPoints)
        streakDays = try c.decode(Int.self, forKey: .streakDays)
        streakShields = try c.decode(Int.self, forKey: .streakShields)
        lastFocusDate = try c.decodeIfPresent(String.self, forKey: .lastFocusDate)
        lastDailyReset = try c.decodeIfPresent(String.self, forKey: .lastDailyReset)
        totalFocusMinutes = try c.decode(Int.self, forKey: .totalFocusMinutes)
        totalSessions = try c.decode(Int.self, forKey: .totalSessions)
        bossHP = try c.decode(Int.self, forKey: .bossHP)
        bossMaxHP = try c.decode(Int.self, forKey: .bossMaxHP)
        currentBossIndex = try c.decode(Int.self, forKey: .currentBossIndex)
        bossDamageThisWeek = try c.decode(Int.self, forKey: .bossDamageThisWeek)
        bossDefeats = try c.decode(Int.self, forKey: .bossDefeats)
        questProgress = try c.decode([String: Double].self, forKey: .questProgress)
        questCompleted = try c.decode([String: Bool].self, forKey: .questCompleted)
        skills = try c.decode([String: Bool].self, forKey: .skills)
        focusHistory = try c.decode([FocusDay].self, forKey: .focusHistory)
        weeklyFocusMinutes = try c.decode([Int].self, forKey: .weeklyFocusMinutes)
        bestStreak = try c.decode(Int.self, forKey: .bestStreak)
        recentSessions = (try? c.decode([FocusSession].self, forKey: .recentSessions)) ?? []
        recentLabels = (try? c.decode([String].self, forKey: .recentLabels)) ?? []
        // New rotating quest fields — default to empty/zero if missing from saved state
        activeDailyQuests = (try? c.decode([String].self, forKey: .activeDailyQuests)) ?? []
        activeWeeklyQuests = (try? c.decode([String].self, forKey: .activeWeeklyQuests)) ?? []
        lastWeeklyReset = try? c.decode(String.self, forKey: .lastWeeklyReset)
        weeklySkillsUnlocked = (try? c.decode(Int.self, forKey: .weeklySkillsUnlocked)) ?? 0
        weeklyEarlySessions = (try? c.decode(Int.self, forKey: .weeklyEarlySessions)) ?? 0
    }

    // Memberwise initializer (used by defaultState and other call sites).
    init(
        xp: Int, level: Int, skillPoints: Int,
        streakDays: Int, streakShields: Int,
        lastFocusDate: String?, lastDailyReset: String?,
        totalFocusMinutes: Int, totalSessions: Int,
        bossHP: Int, bossMaxHP: Int,
        currentBossIndex: Int, bossDamageThisWeek: Int, bossDefeats: Int,
        questProgress: [String: Double],
        questCompleted: [String: Bool],
        skills: [String: Bool],
        focusHistory: [FocusDay],
        weeklyFocusMinutes: [Int],
        bestStreak: Int,
        recentSessions: [FocusSession] = [],
        recentLabels: [String] = [],
        activeDailyQuests: [String] = [],
        activeWeeklyQuests: [String] = [],
        lastWeeklyReset: String? = nil,
        weeklySkillsUnlocked: Int = 0,
        weeklyEarlySessions: Int = 0
    ) {
        self.xp = xp
        self.level = level
        self.skillPoints = skillPoints
        self.streakDays = streakDays
        self.streakShields = streakShields
        self.lastFocusDate = lastFocusDate
        self.lastDailyReset = lastDailyReset
        self.totalFocusMinutes = totalFocusMinutes
        self.totalSessions = totalSessions
        self.bossHP = bossHP
        self.bossMaxHP = bossMaxHP
        self.currentBossIndex = currentBossIndex
        self.bossDamageThisWeek = bossDamageThisWeek
        self.bossDefeats = bossDefeats
        self.questProgress = questProgress
        self.questCompleted = questCompleted
        self.skills = skills
        self.focusHistory = focusHistory
        self.weeklyFocusMinutes = weeklyFocusMinutes
        self.bestStreak = bestStreak
        self.recentSessions = recentSessions
        self.recentLabels = recentLabels
        self.activeDailyQuests = activeDailyQuests
        self.activeWeeklyQuests = activeWeeklyQuests
        self.lastWeeklyReset = lastWeeklyReset
        self.weeklySkillsUnlocked = weeklySkillsUnlocked
        self.weeklyEarlySessions = weeklyEarlySessions
    }
}

// MARK: - Evolution Stages

struct EvolutionStage {
    let name: String
    let minLevel: Int
    let maxLevel: Int
    let tails: Int
    let emoji: String
    let color: String  // hex
}

let evolutionStages: [EvolutionStage] = [
    EvolutionStage(name: "Ember Kit", minLevel: 1, maxLevel: 10, tails: 1, emoji: "🦊", color: "#f97316"),
    EvolutionStage(name: "Focus Pup", minLevel: 11, maxLevel: 25, tails: 2, emoji: "🦊", color: "#fb923c"),
    EvolutionStage(name: "Spirit Runner", minLevel: 26, maxLevel: 50, tails: 3, emoji: "🦊", color: "#38bdf8"),
    EvolutionStage(name: "Mystic Guardian", minLevel: 51, maxLevel: 80, tails: 5, emoji: "🦊", color: "#7c3aed"),
    EvolutionStage(name: "Kitsune Legend", minLevel: 81, maxLevel: 100, tails: 9, emoji: "🦊", color: "#fbbf24"),
]
