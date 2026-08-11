import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws Lockout's custom block screen over shielded apps.
class ShieldConfigurationProvider: ShieldConfigurationDataSource {
    private var config: ShieldConfiguration {
        let suite = UserDefaults(suiteName: "group.com.lockout.app")!
        let goal = max(15, suite.object(forKey: "goalMinutes") as? Int ?? 45)
        let progress = suite.integer(forKey: "progressMinutes")
        let remaining = max(0, goal - progress)
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "figure.strengthtraining.traditional"),
            title: .init(text: "Locked out 🔒", color: .white),
            subtitle: .init(text: "\(remaining) min at the gym to unlock. Earn it.",
                            color: .lightGray),
            primaryButtonLabel: .init(text: "I'm on it", color: .black),
            primaryButtonBackgroundColor: .white
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration { config }
    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration { config }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { config }
}
