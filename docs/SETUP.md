# Setup guide — accounts, entitlements, and the things only the founder can do

Everything in this file requires Ivan's personal/company accounts. Do these in order;
**step 2 is the longest lead time in the whole project — do it first.**

## 1. Trademark & domains (1–2 h)

- Search "Lockout" app-store collisions: App Store, Google Play, USPTO TESS (https://tmsearch.uspto.gov).
- Check domains: `lockout.app`, `getlockout.com`, `lockoutapp.com`. Grab socials: `@lockoutapp`.
- If "Lockout" alone is taken as an app name, register the store listing as
  **"Lockout: Sweat to Unlock"** (brand stays "Lockout").
- Plan B name: **Spotter**.

## 2. Apple Developer + Family Controls entitlement (start week 1 — weeks of lead time)

1. Enroll in the Apple Developer Program (org account recommended, $99/yr).
2. Create the App ID `com.lockout.app` (+ extension IDs, see ios/README.md).
3. Request the **Family Controls (Distribution)** entitlement:
   https://developer.apple.com/contact/request/family-controls-distribution
   — while it's pending you can develop with the development entitlement on device.

### Draft justification text (edit and submit)

> Lockout is a digital wellbeing app. Users voluntarily select apps and website
> categories they find distracting; Lockout shields those apps using the Screen Time
> API (FamilyControls, ManagedSettings, DeviceActivity) until the user completes a
> self-chosen fitness goal — e.g. a gym visit of at least 15 minutes verified by
> geofencing, or a workout recorded in HealthKit. The app is used by adults on their
> own devices (no parent/child remote control in v1). We use FamilyActivityPicker so
> Lockout never learns which specific apps the user blocks; shielding decisions and
> location processing happen on device. The entitlement is required to apply and
> remove shields (ManagedSettingsStore) and to customize the shield screen with the
> user's remaining-goal progress.

## 3. Google Play Console (1 day)

1. Create a Play Console developer account ($25 one-time).
2. Prepare the **AccessibilityService declaration** (Play policy: "permitted use —
   digital wellbeing"). Draft wording:

> Lockout uses the AccessibilityService API solely to detect when a user-blocked app
> comes to the foreground so it can display a blocking screen, as part of a digital
> wellbeing feature the user explicitly configures and can disable. No content is
> read from the screen, no data is collected via the service, and nothing is shared
> with third parties.

3. Also declared: `SYSTEM_ALERT_WINDOW` (blocking overlay), `PACKAGE_USAGE_STATS`
   (screen-time stats), location (geofenced gym check-in), Health Connect read
   permissions (workout verification).

## 4. Supabase project (30 min)

1. Create a project at https://supabase.com (region: `us-east-1` — US-first audience).
2. Run `backend/supabase/migrations/0001_init.sql`.
3. Copy the project URL + anon key into the mobile apps' config (see each README).

## 5. Test hardware

- iPhone (iOS 17+) + Apple Watch — Screen Time APIs **do not work on the simulator**.
- Android phone (Android 10+) + any Wear OS / Health Connect-compatible band.
- A real gym membership for geofence field testing 🙂
