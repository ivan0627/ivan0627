# Lockout iOS spike

Proves the core loop on device: pick apps → shield them → gym geofence dwell ≥ goal →
shield lifts for the configured reward window.

## Build

```bash
brew install xcodegen
cd ios
xcodegen generate
open Lockout.xcodeproj
```

1. Set your Team ID in `project.yml` (`DEVELOPMENT_TEAM`) or in Xcode signing settings.
2. Run on a **physical device** (Screen Time APIs don't work on the simulator).
3. First launch asks for Screen Time authorization (works with the development
   entitlement while the distribution one is pending — see docs/SETUP.md).

## Targets

| Target | Role |
|---|---|
| `Lockout` | App: onboarding, app picker, gym setup, dwell tracking, unlock engine |
| `ShieldConfigExtension` | Draws the custom block screen ("32 min of gym to go") |
| `ShieldActionExtension` | Handles taps on the shield's button |
| `MonitorExtension` | DeviceActivity schedule — re-arms the shield at the daily reset |

State is shared with the extensions through the `group.com.lockout.app` app group
(`SharedState.swift`).

## Spike test script

1. Onboard, authorize Screen Time, pick 1–2 apps to block, confirm shield appears.
2. Register a "gym" at your current location with a 100 m radius, set goal to 15 min.
3. Walk away (exit region), come back, stay 15 min → notification + apps open.
4. Kill the app and repeat — geofence events must relaunch it in background.
