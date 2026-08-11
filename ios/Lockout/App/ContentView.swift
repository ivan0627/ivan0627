import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var auth: AuthorizationService
    @EnvironmentObject var gymStore: GymStore
    @EnvironmentObject var sessionTracker: GymSessionTracker
    @EnvironmentObject var geofence: GeofenceService
    @EnvironmentObject var health: HealthService

    @State private var selection = SharedState.blockedSelection
    @State private var showPicker = false
    @State private var goalMinutes = Double(SharedState.goalMinutes)
    private let tick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                statusSection
                blockingSection
                gymSection
                settingsSection
            }
            .navigationTitle("Lockout")
            .onReceive(tick) { _ in sessionTracker.tick() }
        }
    }

    private var statusSection: some View {
        Section("Today") {
            if SharedState.isUnlocked {
                Label("Unlocked until \(SharedState.unlockUntil!.formatted(date: .omitted, time: .shortened))",
                      systemImage: "lock.open.fill").foregroundStyle(.green)
            } else {
                Label("\(sessionTracker.accumulatedMinutes) / \(Int(goalMinutes)) min at the gym",
                      systemImage: sessionTracker.isInsideGym ? "figure.strengthtraining.traditional" : "lock.fill")
            }
        }
    }

    private var blockingSection: some View {
        Section("Blocked apps") {
            if !auth.isAuthorized {
                Button("Authorize Screen Time") { Task { await auth.requestAuthorization() } }
            }
            Button("Choose apps & sites to block") { showPicker = true }
                .disabled(!auth.isAuthorized)
                .familyActivityPicker(isPresented: $showPicker, selection: $selection)
                .onChange(of: selection) { _, newValue in
                    SharedState.blockedSelection = newValue
                    ShieldController.refresh()
                }
            Text("\(selection.applicationTokens.count) apps · \(selection.categoryTokens.count) categories · \(selection.webDomainTokens.count) sites")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var gymSection: some View {
        Section("My gyms") {
            ForEach(gymStore.gyms) { gym in
                Label(gym.name, systemImage: "mappin.and.ellipse")
            }
            .onDelete { indexSet in
                indexSet.map { gymStore.gyms[$0] }.forEach(gymStore.remove)
                geofence.startMonitoring(gyms: gymStore.gyms)
            }
            Button("Add current location as my gym") {
                geofence.requestPermissions()
                geofence.requestCurrentLocation()
                if let coordinate = geofence.currentCoordinate {
                    gymStore.add(name: "My gym #\(gymStore.gyms.count + 1)", coordinate: coordinate)
                    geofence.startMonitoring(gyms: gymStore.gyms)
                }
            }
        }
    }

    private var settingsSection: some View {
        Section("Goal") {
            VStack(alignment: .leading) {
                Text("Daily goal: \(Int(goalMinutes)) min")
                Slider(value: $goalMinutes, in: 15...120, step: 5) { editing in
                    if !editing { SharedState.goalMinutes = Int(goalMinutes) }
                }
            }
            Button("Connect Apple Health") { Task { await health.requestAuthorization() } }
            Button("Check external workouts (tennis, hiking…)") {
                Task {
                    let workouts = await health.todaysQualifyingWorkouts(minMinutes: SharedState.goalMinutes)
                    if let workout = workouts.first {
                        UnlockEngine.grantUnlock(reason: "Workout verified: \(Int(workout.duration / 60)) min")
                    }
                }
            }
        }
    }
}
