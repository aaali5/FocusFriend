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
    // Daily (rotating pool — 3 selected each day)
    Quest(id: "daily-1", title: "Morning Focus", description: "Complete a 25-min session before 10am", target: 1, xpReward: 150, category: .daily, unit: "session"),
    Quest(id: "daily-2", title: "Deep Dive", description: "Complete a 60-min session without interruption", target: 1, xpReward: 250, category: .daily, unit: "session"),
    Quest(id: "daily-3", title: "Triple Threat", description: "Complete 3 focus sessions today", target: 3, xpReward: 200, category: .daily, unit: "sessions"),
    Quest(id: "daily-4", title: "Early Bird", description: "Start a focus session before 8am", target: 1, xpReward: 175, category: .daily, unit: "session"),
    Quest(id: "daily-5", title: "Power Hour", description: "Accumulate 60 minutes of focus today", target: 60, xpReward: 200, category: .daily, unit: "minutes"),
    Quest(id: "daily-6", title: "Quick Burst", description: "Complete a 15-minute session", target: 1, xpReward: 100, category: .daily, unit: "session"),
    Quest(id: "daily-7", title: "Double Down", description: "Complete 2 sessions back to back", target: 2, xpReward: 175, category: .daily, unit: "sessions"),
    Quest(id: "daily-8", title: "Night Owl", description: "Focus session after 8pm", target: 1, xpReward: 150, category: .daily, unit: "session"),
    Quest(id: "daily-9", title: "Half Hour Hero", description: "Complete a 30+ minute session", target: 1, xpReward: 150, category: .daily, unit: "session"),
    Quest(id: "daily-10", title: "Afternoon Push", description: "Focus session between 1-5pm", target: 1, xpReward: 125, category: .daily, unit: "session"),
    Quest(id: "daily-11", title: "Marathon Prep", description: "Accumulate 90 minutes today", target: 90, xpReward: 250, category: .daily, unit: "minutes"),
    Quest(id: "daily-12", title: "Four-Timer", description: "Complete 4 focus sessions today", target: 4, xpReward: 275, category: .daily, unit: "sessions"),
    Quest(id: "daily-13", title: "Beat Yesterday", description: "Focus more minutes than yesterday", target: 1, xpReward: 200, category: .daily, unit: "session"),
    Quest(id: "daily-14", title: "Sunrise Grind", description: "Complete a 45-min session before noon", target: 1, xpReward: 225, category: .daily, unit: "session"),
    Quest(id: "daily-15", title: "Steady Pace", description: "Focus for at least 20 minutes", target: 1, xpReward: 100, category: .daily, unit: "session"),
    // Weekly (rotating pool — 2 selected each week)
    Quest(id: "weekly-1", title: "Marathon Week", description: "Accumulate 10+ hours of total focus time", target: 10, xpReward: 800, category: .weekly, unit: "hours"),
    Quest(id: "weekly-2", title: "Consistency Crown", description: "Focus every day this week (7 days)", target: 7, xpReward: 1000, category: .weekly, unit: "days"),
    Quest(id: "weekly-3", title: "Early Riser", description: "Start 3 sessions before 9am this week", target: 3, xpReward: 600, category: .weekly, unit: "sessions"),
    Quest(id: "weekly-4", title: "Boss Slayer", description: "Deal 200+ HP boss damage this week", target: 200, xpReward: 750, category: .weekly, unit: "HP"),
    Quest(id: "weekly-5", title: "Session Streak", description: "Complete at least 1 session for 5 consecutive days", target: 5, xpReward: 900, category: .weekly, unit: "days"),
    Quest(id: "weekly-6", title: "Skill Builder", description: "Unlock 2 skill nodes this week", target: 2, xpReward: 700, category: .weekly, unit: "skills"),
    // Epic
    Quest(id: "epic-1", title: "The Hundred", description: "Complete 100 total focus sessions", target: 100, xpReward: 5000, category: .epic, unit: "sessions"),
    Quest(id: "epic-2", title: "Iron Will", description: "Achieve a 30-day focus streak", target: 30, xpReward: 8000, category: .epic, unit: "days"),
    Quest(id: "epic-3", title: "Time Lord", description: "Accumulate 500 total hours of focus", target: 500, xpReward: 15000, category: .epic, unit: "hours"),
]

let bosses: [Boss] = [
    Boss(name: "Doom Scroller", type: "Social Media Serpent", emoji: "🐍", description: "A venomous serpent that feeds on endless scrolling. Its hypnotic gaze keeps victims trapped in feeds forever.", color: "#ef4444"),
    Boss(name: "Notification Swarm", type: "Buzzing Insect Horde", emoji: "🐝", description: "A relentless swarm of buzzing notifications. Each ping saps your focus and feeds the horde.", color: "#eab308"),
    Boss(name: "Procrastination Phantom", type: "Shadowy Ghost", emoji: "👻", description: "An ethereal phantom that whispers 'just five more minutes.' Its touch drains motivation and warps time.", color: "#8b5cf6"),
    Boss(name: "Doomscroll Dragon", type: "Ancient Feed Wyrm", emoji: "🐉", description: "An ancient dragon whose breath pulls you into infinite feeds. Each scale is a lost hour.", color: "#dc2626"),
    Boss(name: "Anxiety Imp", type: "Worry Sprite", emoji: "👹", description: "A jittery imp that floods your mind with what-ifs. It grows stronger when you check your phone.", color: "#f59e0b"),
    Boss(name: "FOMO Wraith", type: "Fear Specter", emoji: "💀", description: "A hollow specter that convinces you everything important is happening without you.", color: "#6366f1"),
    Boss(name: "Tab Hydra", type: "Multi-headed Browser Beast", emoji: "🐙", description: "Every tab you open grows a new head. Only deep focus can sever them all.", color: "#14b8a6"),
    Boss(name: "Burnout Phoenix", type: "Exhaustion Firebird", emoji: "🔥", description: "Born from overwork, it rises when you ignore rest. Balance is the only weapon.", color: "#f43f5e"),
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
