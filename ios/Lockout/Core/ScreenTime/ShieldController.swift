import ManagedSettings
import FamilyControls

/// Applies/removes the shield over the user's blocked selection.
/// Single source of truth: SharedState (selection + unlockUntil).
enum ShieldController {
    private static let store = ManagedSettingsStore(named: .init("lockout.main"))

    /// Re-evaluates state and applies the correct shield. Safe to call repeatedly.
    static func refresh() {
        guard !SharedState.isUnlocked else { return removeShield() }
        let selection = SharedState.blockedSelection
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
    }

    static func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
