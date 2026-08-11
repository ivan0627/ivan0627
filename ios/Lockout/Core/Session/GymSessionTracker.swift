import Foundation

/// Accumulates verified dwell time inside a gym geofence.
/// Short exits (< graceSeconds) don't end the session — bathroom breaks,
/// stepping out for a call, GPS jitter at the fence edge.
final class GymSessionTracker: ObservableObject {
    static let graceSeconds: TimeInterval = 5 * 60

    private enum Key {
        static let enteredAt = "session.enteredAt"
        static let bankedSeconds = "session.bankedSeconds"
        static let exitedAt = "session.exitedAt"
        static let lastGoalDate = "session.lastGoalDate"
    }

    private let defaults = SharedState.suite
    @Published private(set) var isInsideGym = false

    // MARK: - Geofence events (may fire with the app freshly relaunched in background)

    func regionEntered(regionId: String) {
        isInsideGym = true
        if let exitedAt = defaults.object(forKey: Key.exitedAt) as? Date,
           Date.now.timeIntervalSince(exitedAt) < Self.graceSeconds {
            // Re-entry within grace: resume, keep banked time, don't reset enteredAt.
            defaults.removeObject(forKey: Key.exitedAt)
        } else {
            defaults.set(Date.now, forKey: Key.enteredAt)
            defaults.set(0.0, forKey: Key.bankedSeconds)
            defaults.removeObject(forKey: Key.exitedAt)
        }
        checkGoal()
    }

    func regionExited(regionId: String) {
        isInsideGym = false
        bankElapsed()
        defaults.set(Date.now, forKey: Key.exitedAt)
        defaults.removeObject(forKey: Key.enteredAt)
        checkGoal()
    }

    /// Called from foreground timer ticks and background app refresh.
    func tick() { checkGoal() }

    // MARK: - Accounting

    var accumulatedMinutes: Int {
        var seconds = defaults.double(forKey: Key.bankedSeconds)
        if let enteredAt = defaults.object(forKey: Key.enteredAt) as? Date {
            seconds += Date.now.timeIntervalSince(enteredAt)
        }
        return Int(seconds / 60)
    }

    private func bankElapsed() {
        guard let enteredAt = defaults.object(forKey: Key.enteredAt) as? Date else { return }
        let banked = defaults.double(forKey: Key.bankedSeconds)
        defaults.set(banked + Date.now.timeIntervalSince(enteredAt), forKey: Key.bankedSeconds)
    }

    private func checkGoal() {
        SharedState.progressMinutes = accumulatedMinutes
        let today = Calendar.current.startOfDay(for: .now)
        let alreadyGranted = (defaults.object(forKey: Key.lastGoalDate) as? Date) == today
        guard !alreadyGranted, accumulatedMinutes >= SharedState.goalMinutes else { return }
        defaults.set(today, forKey: Key.lastGoalDate)
        // TODO(anti-cheat v1): in "proof mode", require a HealthService workout /
        // heart-rate check over this window before granting.
        UnlockEngine.grantUnlock(reason: "Gym session: \(accumulatedMinutes) min")
    }
}
