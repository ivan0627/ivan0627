import SwiftUI
import UserNotifications

@main
struct LockoutApp: App {
    @StateObject private var auth = AuthorizationService()
    @StateObject private var gymStore = GymStore()
    @StateObject private var sessionTracker: GymSessionTracker
    @StateObject private var geofence: GeofenceService
    @StateObject private var health = HealthService()

    init() {
        let tracker = GymSessionTracker()
        _sessionTracker = StateObject(wrappedValue: tracker)
        _geofence = StateObject(wrappedValue: GeofenceService(sessionTracker: tracker))
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(gymStore)
                .environmentObject(sessionTracker)
                .environmentObject(geofence)
                .environmentObject(health)
                .onAppear {
                    geofence.startMonitoring(gyms: gymStore.gyms)
                    ShieldController.refresh()
                }
        }
    }
}
