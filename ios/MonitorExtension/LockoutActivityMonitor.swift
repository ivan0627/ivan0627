import DeviceActivity
import ManagedSettings
import FamilyControls

/// Runs out-of-process on DeviceActivity schedule boundaries, so the shield
/// re-arms when the reward window ends even if the app was killed.
class LockoutActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init("lockout.main"))
    private let suite = UserDefaults(suiteName: "group.com.lockout.app")!

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == DeviceActivityName("lockout.rewardWindow") else { return }
        suite.removeObject(forKey: "unlockUntil")
        suite.set(0, forKey: "progressMinutes")
        reapplyShield()
    }

    private func reapplyShield() {
        guard let data = suite.data(forKey: "blockedSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
    }
}
