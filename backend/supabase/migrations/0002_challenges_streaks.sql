-- Lockout — daily challenge templates + streak computation

create table challenge_templates (
  id text primary key,
  title text not null,          -- en-US copy; clients localize by template id
  description text not null,
  metric text not null check (metric in ('steps', 'active_kcal', 'exercise_minutes', 'workout_any')),
  default_target int not null,
  deadline_hour int check (deadline_hour between 1 and 23)  -- null = end of day
);

insert into challenge_templates (id, title, description, metric, default_target, deadline_hour) values
  ('steps_7k_sunset', '7K before sunset',  'Hit 7,000 steps before 6 PM.',            'steps',            7000, 18),
  ('kcal_300',        'Burn 300',          'Burn 300 active calories today.',          'active_kcal',       300, null),
  ('move_45',         'Move 45',           'Log 45 minutes of exercise today.',        'exercise_minutes',   45, null),
  ('any_workout_30',  'Anything counts',   'Any workout of at least 30 minutes — tennis, hike, hoops, you pick.',
                                                                                       'workout_any',        30, null),
  ('steps_10k',       'The classic 10K',   'Hit 10,000 steps before midnight.',        'steps',           10000, null),
  ('kcal_450',        'Furnace day',       'Burn 450 active calories today.',          'active_kcal',       450, null);

-- Deterministic rotation by day-of-year: every client asking for the same date
-- gets the same challenge, no scheduler needed. Difficulty personalization
-- replaces default_target in Fase 2.
create or replace function ensure_daily_challenge(day date default current_date)
returns daily_challenges
language plpgsql as $$
declare
  result daily_challenges;
begin
  insert into daily_challenges (challenge_date, template_id, params)
  select day, t.id,
         jsonb_build_object('target', t.default_target, 'deadline_hour', t.deadline_hour,
                            'metric', t.metric)
  from (
    select id, default_target, deadline_hour, metric,
           row_number() over (order by id) as rn,
           count(*) over () as total
    from challenge_templates
  ) t
  where t.rn = (extract(doy from day)::int % t.total) + 1
  on conflict (challenge_date) do nothing;

  select * into result from daily_challenges where challenge_date = day;
  return result;
end;
$$;

-- A day counts toward the streak when the user EARNED an unlock that day
-- (gym, challenge or activity — emergency keys never count).
-- NOTE(v1): dates are UTC; per-user timezone (users.settings->>'tz') lands with
-- the streak-freeze work in Fase 2.
create view user_active_days as
  select user_id, (granted_at at time zone 'utc')::date as active_date
  from unlocks
  where granted_by <> 'emergency_key'
  group by 1, 2;

-- Consecutive-day streak ending today or yesterday (an unbroken streak isn't
-- lost until a full day passes with no earned unlock).
create or replace function current_streak(uid uuid, today date default current_date)
returns int
language sql stable as $$
  with anchor as (
    select max(active_date) as last_day
    from user_active_days
    where user_id = uid and active_date <= today
  ),
  run as (
    select count(*) as len
    from (
      select active_date,
             (row_number() over (order by active_date desc) - 1)::int as off
      from user_active_days
      where user_id = uid and active_date <= today
    ) d, anchor a
    where d.active_date = a.last_day - d.off
  )
  select case
    when (select last_day from anchor) is null then 0
    when (select last_day from anchor) < today - 1 then 0
    else (select len from run)
  end;
$$;
