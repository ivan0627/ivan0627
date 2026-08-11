# Lockout Android spike

Proves the core loop: pick apps → AccessibilityService detects them opening →
full-screen overlay blocks them → gym geofence dwell ≥ goal → unlocked for the
reward window.

## Build

Open `android/` in Android Studio (Ladybug or newer) and run on a **physical
device** (geofencing and Health Connect are unreliable on emulators).

## Components

| Component | Role |
|---|---|
| `MainActivity` | Spike UI: permission checklist, blocked-app switches, gym setup, goal slider |
| `blocking/AppBlockerService` | AccessibilityService — detects blocked app in foreground |
| `blocking/BlockOverlayController` | Full-screen "Locked out" overlay |
| `location/GeofenceManager` + `GeofenceBroadcastReceiver` | Gym geofences → session events |
| `session/GymSessionService` | Foreground service counting dwell minutes (5-min exit grace) |
| `unlock/UnlockManager` | Shared state: blocked set, goal, progress, unlock window |
| `health/HealthConnectService` | Workout / heart-rate verification (Health Connect) |

## Spike test script

1. Complete the 4 setup buttons (accessibility, overlay, location, background location).
2. Toggle Instagram/TikTok on, open one → black "Locked out 🔒" screen must appear.
3. Add your current location as gym, set goal to 15 min, take a walk out and back.
4. Stay 15 min inside → notification progress hits goal → blocked apps open.
5. Reboot the phone and confirm geofence events still arrive (Play Services re-registers).

## Known spike gaps (deliberate)

- Daily reset (`UnlockManager.resetDay`) not yet scheduled — wire to WorkManager in Fase 2.
- Health Connect qualifying-session check not yet wired into the UI.
- Blocked-website detection (browser URL) is v1, not in this spike.
