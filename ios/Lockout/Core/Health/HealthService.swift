import HealthKit

/// Reads workouts / active energy / heart rate to verify training.
/// Spike scope: fetch today's workouts so an external activity (tennis, hiking…)
/// recorded by the watch can grant an unlock. Proof-mode HR cross-check lands
/// in Fase 2 (see PLAN.md §3.4).
final class HealthService: ObservableObject {
    private let store = HKHealthStore()
    @Published private(set) var isAuthorized = false

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let read: Set<HKObjectType> = [
            .workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.stepCount),
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: read)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Workouts that already qualify for an unlock today: right duration, recent,
    /// and any activity type (tennis, basketball, hiking… all count).
    func todaysQualifyingWorkouts(minMinutes: Int) async -> [HKWorkout] {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(), predicate: predicate, limit: 20,
                sortDescriptors: [.init(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout] ?? []).filter {
                    $0.duration >= Double(minMinutes) * 60
                    && Date.now.timeIntervalSince($0.endDate) < 3 * 3600 // no recycling old workouts
                }
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    /// Checks the watch actually saw effort during a gym session window ("proof mode").
    func hadElevatedEffort(from: Date, to: Date, minAvgHeartRate: Double = 95) async -> Bool {
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(.heartRate),
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                let bpm = stats?.averageQuantity()?
                    .doubleValue(for: .count().unitDivided(by: .minute())) ?? 0
                continuation.resume(returning: bpm >= minAvgHeartRate)
            }
            store.execute(query)
        }
    }
}
