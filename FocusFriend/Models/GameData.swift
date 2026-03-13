import Foundation

// MARK: - Quest

struct Quest: Identifiable {
    let id: String
    let title: String
    let description: String
    let target: Double
    let xpReward: Int
    let category: QuestCategory
    let unit: String
}

enum QuestCategory: String, CaseIterable {
    case daily, weekly, epic
    var label: String { rawValue.capitalized }
}

// MARK: - Boss

struct Boss: Identifiable {
    var id: String { name }
    let name: String
    let type: String
    let emoji: String
    let description: String
    let color: String
}

// MARK: - Skill Node

struct SkillNode: Identifiable {
    let id: String
    let name: String
    let description: String
    let branch: SkillBranch
    let tier: Int
    let requires: String?
}

enum SkillBranch: String, CaseIterable {
    case endurance, consistency, intensity
    var label: String { rawValue.capitalized }
    var color: String {
        switch self {
        case .endurance: return "#f97316"
        case .consistency: return "#38bdf8"
        case .intensity: return "#7c3aed"
        }
    }
}

// MARK: - Data

let quests: [Quest] = [
    // Daily
    Quest(id: "daily-1", title: "Morning Focus", description: "Complete a 25-min session before 10am", target: 1, xpReward: 150, category: .daily, unit: "session"),
    Quest(id: "daily-2", title: "Deep Dive", description: "Complete a 60-min session without interruption", target: 1, xpReward: 250, category: .daily, unit: "session"),
    Quest(id: "daily-3", title: "Triple Threat", description: "Complete 3 focus sessions today", target: 3, xpReward: 200, category: .daily, unit: "sessions"),
    // Weekly
    Quest(id: "weekly-1", title: "Marathon Week", description: "Accumulate 10+ hours of total focus time", target: 10, xpReward: 800, category: .weekly, unit: "hours"),
    Quest(id: "weekly-2", title: "Consistency Crown", description: "Focus every day this week (7 days)", target: 7, xpReward: 1000, category: .weekly, unit: "days"),
    // Epic
    Quest(id: "epic-1", title: "The Hundred", description: "Complete 100 total focus sessions", target: 100, xpReward: 5000, category: .epic, unit: "sessions"),
    Quest(id: "epic-2", title: "Iron Will", description: "Achieve a 30-day focus streak", target: 30, xpReward: 8000, category: .epic, unit: "days"),
    Quest(id: "epic-3", title: "Time Lord", description: "Accumulate 500 total hours of focus", target: 500, xpReward: 15000, category: .epic, unit: "hours"),
]

let bosses: [Boss] = [
    Boss(name: "Doom Scroller", type: "Social Media Serpent", emoji: "🐍", description: "A venomous serpent that feeds on endless scrolling. Its hypnotic gaze keeps victims trapped in feeds forever.", color: "#ef4444"),
    Boss(name: "Notification Swarm", type: "Buzzing Insect Horde", emoji: "🐝", description: "A relentless swarm of buzzing notifications. Each ping saps your focus and feeds the horde.", color: "#eab308"),
    Boss(name: "Procrastination Phantom", type: "Shadowy Ghost", emoji: "👻", description: "An ethereal phantom that whispers 'just five more minutes.' Its touch drains motivation and warps time.", color: "#8b5cf6"),
]

let skillTree: [SkillNode] = [
    // Endurance
    SkillNode(id: "endurance-1", name: "Iron Focus", description: "+5 XP per minute during sessions", branch: .endurance, tier: 1, requires: nil),
    SkillNode(id: "endurance-2", name: "Extended Session", description: "Unlock 90-min timer option", branch: .endurance, tier: 2, requires: "endurance-1"),
    SkillNode(id: "endurance-3", name: "Second Wind", description: "2x XP for the last 10 min of any session", branch: .endurance, tier: 3, requires: "endurance-2"),
    SkillNode(id: "endurance-4", name: "Marathon Master", description: "+50% boss damage from sessions over 45 min", branch: .endurance, tier: 4, requires: "endurance-3"),
    // Consistency
    SkillNode(id: "consistency-1", name: "Routine Power", description: "Morning sessions give +25% XP bonus", branch: .consistency, tier: 1, requires: nil),
    SkillNode(id: "consistency-2", name: "Streak Shield", description: "Earn streak shields every 5 days", branch: .consistency, tier: 2, requires: "consistency-1"),
    SkillNode(id: "consistency-3", name: "Daily Discipline", description: "Auto-complete 1 daily quest per day", branch: .consistency, tier: 3, requires: "consistency-2"),
    SkillNode(id: "consistency-4", name: "Unbreakable", description: "Streak multiplier caps increase to x8", branch: .consistency, tier: 4, requires: "consistency-3"),
    // Intensity
    SkillNode(id: "intensity-1", name: "Deep Focus", description: "+10% XP for uninterrupted sessions", branch: .intensity, tier: 1, requires: nil),
    SkillNode(id: "intensity-2", name: "Flow State", description: "After 20 min, XP rate increases by 25%", branch: .intensity, tier: 2, requires: "intensity-1"),
    SkillNode(id: "intensity-3", name: "Critical Hit", description: "10% chance to deal 3x boss damage", branch: .intensity, tier: 3, requires: "intensity-2"),
    SkillNode(id: "intensity-4", name: "Zen Master", description: "All XP multipliers stack multiplicatively", branch: .intensity, tier: 4, requires: "intensity-3"),
]
