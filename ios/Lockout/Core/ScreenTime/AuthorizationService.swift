import FamilyControls

@MainActor
final class AuthorizationService: ObservableObject {
    @Published var isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }
}
