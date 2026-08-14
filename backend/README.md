# Lockout backend (Supabase)

Postgres schema + edge functions. The clients work fully offline (unlock rules
also run on device); the backend is the source of truth for streaks, social
features, and anti-cheat validation.

## Local development

```bash
npm i -g supabase
cd backend
supabase init          # first time only
supabase start
supabase db reset      # applies migrations/
supabase functions serve validate-unlock
```

## Deploy

```bash
supabase link --project-ref <your-project-ref>
supabase db push
supabase functions deploy validate-unlock
```

## Pieces

- `supabase/migrations/0001_init.sql` — full schema from PLAN.md §5.3 with RLS
  (all rows private by default; social visibility policies land in v1.5).
- `supabase/migrations/0002_challenges_streaks.sql` — challenge templates with
  deterministic daily rotation (`ensure_daily_challenge`) and streak math
  (`current_streak`: consecutive earned days; emergency keys never count; a
  streak survives until a full day is missed).
- `supabase/functions/validate-unlock` — validates gym-session / workout evidence
  and mints `unlocks` rows. Anti-cheat v1: wall-clock sanity, recency windows,
  workout dedupe by `external_ref`.
- `supabase/functions/daily-challenge` — GET today's challenge; POST health-data
  evidence to complete it and earn an unlock.

## Tests

`supabase/tests/test_0002.sql` runs against any Postgres with the migrations
applied (rolls itself back):

```bash
psql -d lockout_test -f supabase/tests/test_0002.sql
```

Covers: challenge determinism and weekly variety; 3-day streaks; emergency keys
excluded; streak alive until a day is fully missed; gaps resetting to 1; stale
streaks reporting 0. All 7 green as of this commit.

## Next

- Wire mobile clients to `validate-unlock` / `daily-challenge` (Fase 2).
- Per-user timezone for streaks + challenge deadlines (currently UTC).
- Push notifications (APNs/FCM) on streak risk and crew events.
