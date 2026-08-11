import CoreLocation

/// Region monitoring around the user's gyms. Region events wake the app in
/// background/terminated state, which is what makes dwell tracking reliable
/// without continuous GPS.
final class GeofenceService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let sessionTracker: GymSessionTracker

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentCoordinate: CLLocationCoordinate2D?

    init(sessionTracker: GymSessionTracker) {
        self.sessionTracker = sessionTracker
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
    }

    func requestPermissions() {
        // Two-step ask (WhenInUse → Always) converts better than asking Always cold.
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse: manager.requestAlwaysAuthorization()
        default: break
        }
    }

    func requestCurrentLocation() { manager.requestLocation() }

    func startMonitoring(gyms: [Gym]) {
        manager.monitoredRegions
            .filter { region in !gyms.contains { $0.id.uuidString == region.identifier } }
            .forEach(manager.stopMonitoring)
        gyms.forEach { manager.startMonitoring(for: $0.region) }
        // Catch the case where the user is already inside when monitoring starts.
        gyms.forEach { manager.requestState(for: $0.region) }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sessionTracker.regionEntered(regionId: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sessionTracker.regionExited(regionId: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState,
                         for region: CLRegion) {
        if state == .inside { sessionTracker.regionEntered(regionId: region.identifier) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentCoordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
