import Foundation

// MARK: - Game State

struct FocusDay: Codable, Identifiable {
    var id: String { date }
    let date: String  // YYYY-MM-DD
    var minutes: Int
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
