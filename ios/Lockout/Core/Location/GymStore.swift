import Foundation
import CoreLocation

struct Gym: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double // 75–150 m recommended

    var region: CLCircularRegion {
        let region = CLCircularRegion(
            center: .init(latitude: latitude, longitude: longitude),
            radius: radiusMeters,
            identifier: id.uuidString)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

final class GymStore: ObservableObject {
    @Published private(set) var gyms: [Gym] {
        didSet { save() }
    }

    private static let key = "gyms"

    init() {
        if let data = SharedState.suite.data(forKey: Self.key),
           let stored = try? JSONDecoder().decode([Gym].self, from: data) {
            gyms = stored
        } else {
            gyms = []
        }
    }

    func add(name: String, coordinate: CLLocationCoordinate2D, radius: Double = 100) {
        gyms.append(Gym(id: UUID(), name: name,
                        latitude: coordinate.latitude, longitude: coordinate.longitude,
                        radiusMeters: radius))
    }

    func remove(_ gym: Gym) { gyms.removeAll { $0.id == gym.id } }

    func gym(forRegionId id: String) -> Gym? {
        gyms.first { $0.id.uuidString == id }
    }

    private func save() {
        SharedState.suite.set(try? JSONEncoder().encode(gyms), forKey: Self.key)
    }
}
