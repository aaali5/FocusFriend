import SwiftUI
import UserNotifications

@main
struct FocusFriendApp: App {
    @StateObject private var engine = GameEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                    NotificationManager.scheduleStreakReminder(streakDays: engine.state.streakDays)
                    NotificationManager.scheduleDailyQuestReminder()
                }
        }
    }
}
