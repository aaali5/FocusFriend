import Foundation
import UserNotifications

enum NotificationManager {

    // MARK: - Timer Completion

    static func scheduleTimerCompletion(minutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["timer-complete"])

        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great work! You focused for \(minutes) minutes. Check your XP gains!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "timer-complete", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer-complete"])
    }

    // MARK: - Streak Reminder

    static func scheduleStreakReminder(streakDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])

        let content = UNMutableNotificationContent()
        if streakDays > 0 {
            content.title = "Protect your \(streakDays)-day streak!"
            content.body = "A quick focus session keeps your streak alive."
        } else {
            content.title = "Start a new streak today"
            content.body = "Your spirit fox is waiting. Just 15 minutes to begin."
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "streak-reminder", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    // MARK: - Boss Taunt

    static func scheduleBossTaunt(bossName: String, hpPercent: Int) {
        guard hpPercent <= 25 && hpPercent > 0 else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["boss-taunt"])

        let content = UNMutableNotificationContent()
        content.title = "\(bossName) is almost defeated!"
        content.body = "Only \(hpPercent)% HP remaining. One more session could finish it!"
        content.sound = .default

        // Schedule for tomorrow morning if not focused today
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "boss-taunt", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    // MARK: - Quest Expiring

    static func scheduleDailyQuestReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["quest-expiring"])

        let content = UNMutableNotificationContent()
        content.title = "Daily quests reset soon!"
        content.body = "You still have uncompleted quests. Focus now to earn bonus XP!"
        content.sound = .default

        // Schedule for 9pm
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "quest-expiring", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
}
