import Foundation
import DeviceActivity
import UserNotifications

/// Grants unlocks when a gym session (or, later, a challenge/workout) meets the goal,
/// and schedules the re-lock via the DeviceActivity monitor extension.
enum UnlockEngine {
    static let rewardActivity = DeviceActivityName("lockout.rewardWindow")

    static func grantUnlock(reason: String) {
        let until: Date
        if SharedState.rewardHours > 0 {
            until = .now.addingTimeInterval(TimeInterval(SharedState.rewardHours) * 3600)
        } else {
            until = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: .now) ?? .now
        }
        SharedState.unlockUntil = until
        ShieldController.refresh()
        scheduleRelock(at: until)
        notify(title: "Unlocked 💪",
               body: "\(reason). Your apps are open until \(until.formatted(date: .omitted, time: .shortened)).")
    }

    /// The monitor extension's intervalDidEnd re-applies the shield even if the app
    /// isn't running when the reward window closes.
    private static func scheduleRelock(at until: Date) {
        let center = DeviceActivityCenter()
        center.stopMonitoring([rewardActivity])
        let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let end = Calendar.current.dateComponents([.hour, .minute], from: until)
        let schedule = DeviceActivitySchedule(intervalStart: now, intervalEnd: end, repeats: false)
        try? center.startMonitoring(rewardActivity, during: schedule)
    }

    private static func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
