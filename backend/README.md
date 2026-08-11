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
- `supabase/functions/validate-unlock` — validates gym-session / workout evidence
  and mints `unlocks` rows. Anti-cheat v1: wall-clock sanity, recency windows,
  workout dedupe by `external_ref`.

## Next

- `daily-challenge` function: generates + serves the day's challenge.
- Streak computation (SQL view or scheduled function).
- Push notifications (APNs/FCM) on streak risk and crew events.
