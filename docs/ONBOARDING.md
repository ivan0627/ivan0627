# Onboarding flow & copy (en-US master)

The onboarding is where Lockout wins or dies: we ask for the scariest permission
set on mobile (Screen Time / Accessibility, always-on location, health data).
Every permission gets a **priming screen** — our screen, in our voice, explaining
the why — *before* the system dialog appears. Never fire a system prompt cold.

**Principles**

1. One ask per screen. Never stack permissions.
2. Say what we do AND what we never do ("on this device", "never sold").
3. The user must feel the value before the hardest asks: goal-setting and
   app-picking come first, permissions after.
4. Every screen skippable except Screen Time/Accessibility (the product is
   nothing without it) — skipped permissions re-surface later in context.

---

## Screen 1 — Hook

> **Your feed is costing you your workout.**
> The average person scrolls 4 hours a day and "has no time" for the gym.
> Lockout flips the deal: your apps open when you show up.
>
> [ Let's fix this ]

## Screen 2 — How it works (3 beats, swipeable)

> 1. **Pick your poison.** Choose the apps that eat your time.
> 2. **They lock.** Opening them shows your progress, not your feed.
> 3. **Training unlocks them.** A verified gym session, the daily challenge, or a
>    workout on your watch. You earn your scroll.
>
> [ I'm in ]

## Screen 3 — Set the deal (before any permission)

> **How much gym earns your apps back?**
> Slider: 15 – 120 min (default 45). Under the slider: "15 is the floor. 45 is
> where habits form."
>
> **And for how long?**
> ◉ Until midnight ○ For 2 hours ○ For 4 hours
>
> [ Lock it in ]

## Screen 4 — Pick your apps

> **Which apps own you?**
> Most people block: Instagram, TikTok, YouTube, X.
> iOS: opens FamilyActivityPicker (priming line: "Apple's privacy design means
> we never see which apps you pick — the list stays on your iPhone.")
> Android: in-app list with suggested toggles on top.
>
> [ Block them ]

## Screen 5 — Permission: Screen Time / Accessibility  ⚠️ cannot skip

**iOS**
> **Let Lockout hold the lock.**
> iOS will ask you to allow Screen Time access. That's the mechanism that keeps
> your blocked apps closed — the same one Apple's own downtime uses.
> We can't see your screen, your messages, or your browsing. We just hold the door.
>
> [ Allow Screen Time ] → system dialog

**Android**
> **Let Lockout hold the lock.**
> Android calls this an "accessibility service." For Lockout it does exactly one
> thing: notices when a blocked app opens so we can show your progress screen
> instead. It never reads screen content and never collects data.
>
> [ Turn it on ] → Settings deep-link with inline illustrated steps

## Screen 6 — Permission: Location

> **Your gym is the key.**
> Lockout needs location "Always" so your phone notices you walked into the gym —
> even with the app closed. Your location is processed on this device. We store
> "you trained 47 minutes," never where you've been. Your gym's address is never
> visible to anyone, including your crew.
>
> [ Set my gym ] → map pin → WhenInUse dialog → (later, in context) Always upgrade

*iOS note: the WhenInUse→Always upgrade prompt fires on the first real gym visit
("Make it automatic — allow 'Always' so sessions count with your phone in your
locker"), which converts far better than asking during setup.*

## Screen 7 — Permission: Health (recommended, skippable)

> **Bring your watch. Kill the doubt.**
> Connect Apple Health / Health Connect and your workouts, calories and heart
> rate verify your training — that's what makes tennis, hoops and trail days
> count, and what makes your streak bulletproof to your crew.
> Health data never leaves your device except the single number that proves a
> session (e.g. "42 active minutes"). Never sold, never for ads — that's a
> platform rule and ours.
>
> [ Connect Health ]   [ Later — gym-only mode ]

## Screen 8 — Strict mode (offered, default off)

> **How serious are you?**
> Strict mode locks your settings for a period you choose — 1 day to 4 weeks.
> No pausing, no quitting, no "just this once." You get {n} emergency keys a
> month for real emergencies. Your crew sees when you burn one. 👀
>
> [ Go strict for 1 week ]   [ Start normal ]

## Screen 9 — Done

> **The deal is live.**
> {app icons} lock at {schedule}. {goal} minutes at {gym name} opens them
> until {reward window}.
> Today's challenge if you can't make it: **{challenge title}**.
>
> [ Show me the shield ] → demo of the block screen so the first real block
> is never a surprise

---

## Re-permission nudges (contextual, not naggy)

| Trigger | Nudge |
|---|---|
| Skipped Health, 3rd gym session | "Three sessions this week. Connect your watch and they'd be bulletproof — and trail runs would count too." |
| Location downgraded to WhenInUse | "Your last session didn't count — your phone stopped noticing the gym. Restore 'Always' and it's automatic again." |
| Android battery optimization killing the service | "Your phone is putting Lockout to sleep at the gym. One toggle fixes it." → OEM-specific instructions (Samsung/Xiaomi/Pixel) |

## Localization

All strings live in the string catalog under these keys (`onboarding.hook.title`,
`onboarding.deal.slider_hint`, …). en-US is the source of truth; es-419/es-ES at
launch. Tone rule for translators: coach, not cop — direct, a little cocky,
never shaming.
