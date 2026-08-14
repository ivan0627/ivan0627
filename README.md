# Lockout — Earn your unlock 🏋️🔒

Lockout blocks your distracting apps and only unlocks them when you actually train:
a verified gym session (geofence + dwell time), the daily challenge, or a workout
confirmed by your watch / health device.

> Full product plan (Spanish): [PLAN.md](PLAN.md) · Setup & accounts guide: [docs/SETUP.md](docs/SETUP.md)

## Repository layout

```
ios/        Native iOS app (Swift/SwiftUI) — Screen Time API spike
android/    Native Android app (Kotlin/Compose) — Accessibility + overlay spike
backend/    Supabase schema + edge functions
docs/       Setup guide, entitlement request draft
PLAN.md     Product master plan
```

## Current status (spike phase — Fase 0/1 of the roadmap)

- [x] Product plan and naming (working title: **Lockout**)
- [x] iOS spike scaffold: FamilyControls authorization, app picker, shield on/off,
      gym geofence + dwell tracking, unlock engine, shield UI extension
- [x] Android spike scaffold: AccessibilityService blocker, full-screen overlay,
      geofence + foreground dwell service, unlock manager, Health Connect stub
- [x] Backend schema (Postgres/Supabase) + `validate-unlock` edge function skeleton
- [x] Daily challenges (deterministic rotation) + streak math — **validated against
      real Postgres 16, 7/7 SQL tests green** (`backend/supabase/tests/`)
- [x] Interactive UI prototype (`design/prototype.html`): shield, home, challenge,
      crew and stats screens with a simulated gym session
- [x] Emergency keys + strict mode server rules (monthly quota, 24 h cooldown,
      crew visibility opt-in) — 8/8 SQL tests green
- [x] Full onboarding flow & copy with permission-priming screens (`docs/ONBOARDING.md`)
- [x] Marketing landing page with beta signup (`design/landing.html` — wire the
      form to a list provider before deploying)
- [ ] Apple **Family Controls entitlement** requested (see docs/SETUP.md — blocking, do first)
- [ ] Google Play Console + Accessibility declaration prepared
- [ ] Trademark / domain check for "Lockout"
- [ ] First on-device test of both spikes

## Build quickstart

- **iOS:** requires macOS + Xcode 16+. `brew install xcodegen`, then
  `cd ios && xcodegen generate && open Lockout.xcodeproj`. See [ios/README.md](ios/README.md).
- **Android:** open `android/` in Android Studio (Ladybug+). See [android/README.md](android/README.md).
- **Backend:** `cd backend && supabase start` (local) — see [backend/README.md](backend/README.md).

## Language policy

Product is written **English-first (en-US)** and auto-localized per device locale
(iOS String Catalogs / Android per-locale `strings.xml`). The brand name "Lockout"
is never translated.
