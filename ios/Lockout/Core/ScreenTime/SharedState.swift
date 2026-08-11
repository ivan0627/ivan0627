import Foundation
import FamilyControls

/// State shared between the app and its extensions via the app group.
/// Extensions (shield UI, monitor) run out-of-process and can only see this.
enum SharedState {
    static let suite = UserDefaults(suiteName: "group.com.lockout.app")!

    private enum Key {
        static let selection = "blockedSelection"
        static let unlockUntil = "unlockUntil"
        static let goalMinutes = "goalMinutes"
        static let progressMinutes = "progressMinutes"
        static let rewardHours = "rewardHours" // 0 = rest of day
    }

    static var blockedSelection: FamilyActivitySelection {
        get {
            guard let data = suite.data(forKey: Key.selection),
                  let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return sel
        }
        set { suite.set(try? JSONEncoder().encode(newValue), forKey: Key.selection) }
    }

    static var unlockUntil: Date? {
        get { suite.object(forKey: Key.unlockUntil) as? Date }
        set { suite.set(newValue, forKey: Key.unlockUntil) }
    }

    static var isUnlocked: Bool {
        guard let until = unlockUntil else { return false }
        return until > .now
    }

    /// Minimum 15 min hard floor, default 45.
    static var goalMinutes: Int {
        get { max(15, suite.object(forKey: Key.goalMinutes) as? Int ?? 45) }
        set { suite.set(max(15, newValue), forKey: Key.goalMinutes) }
    }

    /// Verified minutes accumulated today — the shield screen reads this.
    static var progressMinutes: Int {
        get { suite.integer(forKey: Key.progressMinutes) }
        set { suite.set(newValue, forKey: Key.progressMinutes) }
    }

    static var rewardHours: Int {
        get { suite.object(forKey: Key.rewardHours) as? Int ?? 0 }
        set { suite.set(newValue, forKey: Key.rewardHours) }
    }
}
