-- Test suite for 0002: challenge rotation + streak math
\set ON_ERROR_STOP on
begin;

-- 1. Challenge rotation: same date always yields the same challenge; a week has variety
select 'T1 same-date determinism' as test,
  (select template_id from ensure_daily_challenge('2026-08-14')) =
  (select template_id from ensure_daily_challenge('2026-08-14')) as pass;

select 'T2 weekly variety' as test,
  (select count(distinct (ensure_daily_challenge(d::date)).template_id)
   from generate_series('2026-08-10'::date, '2026-08-15'::date, '1 day') d) >= 4 as pass;

-- 2. Streaks
insert into users (id, auth_id, handle) values
  ('00000000-0000-0000-0000-000000000001', gen_random_uuid(), 'ivan');

-- 3 consecutive days ending today → streak 3
insert into unlocks (user_id, granted_by, granted_at, expires_at) values
  ('00000000-0000-0000-0000-000000000001', 'gym',       now() - interval '2 days', now() - interval '2 days' + interval '4 hours'),
  ('00000000-0000-0000-0000-000000000001', 'challenge', now() - interval '1 day',  now() - interval '1 day' + interval '4 hours'),
  ('00000000-0000-0000-0000-000000000001', 'activity',  now(),                     now() + interval '4 hours');

select 'T3 3-day streak' as test,
  current_streak('00000000-0000-0000-0000-000000000001') = 3 as pass;

-- Emergency keys never count
insert into users (id, auth_id, handle) values
  ('00000000-0000-0000-0000-000000000002', gen_random_uuid(), 'cheater');
insert into unlocks (user_id, granted_by, granted_at, expires_at) values
  ('00000000-0000-0000-0000-000000000002', 'emergency_key', now(), now() + interval '4 hours');

select 'T4 emergency key excluded' as test,
  current_streak('00000000-0000-0000-0000-000000000002') = 0 as pass;

-- Streak survives if yesterday was earned but today (not yet) — still shows yesterday's run
insert into users (id, auth_id, handle) values
  ('00000000-0000-0000-0000-000000000003', gen_random_uuid(), 'resting');
insert into unlocks (user_id, granted_by, granted_at, expires_at) values
  ('00000000-0000-0000-0000-000000000003', 'gym', now() - interval '2 days', now() - interval '2 days' + interval '4 hours'),
  ('00000000-0000-0000-0000-000000000003', 'gym', now() - interval '1 day',  now() - interval '1 day' + interval '4 hours');

select 'T5 streak alive until day fully missed' as test,
  current_streak('00000000-0000-0000-0000-000000000003') = 2 as pass;

-- A gap breaks the streak: activity 3 days ago + today → streak 1
insert into users (id, auth_id, handle) values
  ('00000000-0000-0000-0000-000000000004', gen_random_uuid(), 'gapped');
insert into unlocks (user_id, granted_by, granted_at, expires_at) values
  ('00000000-0000-0000-0000-000000000004', 'gym', now() - interval '3 days', now() - interval '3 days' + interval '4 hours'),
  ('00000000-0000-0000-0000-000000000004', 'gym', now(),                     now() + interval '4 hours');

select 'T6 gap resets streak' as test,
  current_streak('00000000-0000-0000-0000-000000000004') = 1 as pass;

-- Streak fully broken 2+ days ago → 0
select 'T7 stale streak is 0' as test,
  current_streak('00000000-0000-0000-0000-000000000004',
                 (now() + interval '5 days')::date) = 0 as pass;

rollback;
