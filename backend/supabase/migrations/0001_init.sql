-- Lockout — initial schema (PLAN.md §5.3)
-- Gym coordinates are user-private; social features only ever expose derived
-- facts ("went to the gym"), never locations.

create table users (
  id uuid primary key default gen_random_uuid(),
  auth_id uuid unique not null,            -- supabase auth.users reference
  handle text unique,
  created_at timestamptz not null default now(),
  settings jsonb not null default '{}'::jsonb
);

create table gyms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  name_alias text not null,                -- "My gym", never shown to others
  lat double precision not null,
  lng double precision not null,
  radius_m int not null default 100 check (radius_m between 50 and 300),
  created_at timestamptz not null default now()
);

create table block_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  goal_minutes int not null default 45 check (goal_minutes >= 15),
  reward_hours int not null default 0,     -- 0 = rest of day
  schedule jsonb not null default '{}'::jsonb,
  strict_until timestamptz,                -- strict-mode commitment end
  emergency_keys_left int not null default 3,
  updated_at timestamptz not null default now()
);

create type verification_level as enum ('location_only', 'biometric');
create type session_status as enum ('active', 'completed', 'flagged');

create table gym_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  gym_id uuid references gyms(id) on delete set null,
  entered_at timestamptz not null,
  exited_at timestamptz,
  verified_minutes int not null default 0,
  verification verification_level not null default 'location_only',
  status session_status not null default 'active',
  created_at timestamptz not null default now()
);

create table workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  source text not null,                    -- healthkit | health_connect | garmin...
  type text not null,                      -- tennis, basketball, hiking...
  started_at timestamptz not null,
  minutes int not null,
  active_kcal int,
  avg_hr int,
  external_ref text,                       -- dedupe key from the source platform
  unique (user_id, external_ref)
);

create table daily_challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null unique,
  template_id text not null,               -- steps_before_6pm, active_kcal, ...
  params jsonb not null default '{}'::jsonb
);

create table challenge_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  challenge_id uuid not null references daily_challenges(id),
  evidence jsonb not null,                 -- aggregated health data, never raw
  completed_at timestamptz not null default now(),
  unique (user_id, challenge_id)
);

create type unlock_source as enum ('gym', 'challenge', 'activity', 'emergency_key');

create table unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  granted_by unlock_source not null,
  evidence_id uuid,                        -- gym_session / workout / completion id
  granted_at timestamptz not null default now(),
  expires_at timestamptz not null
);

-- Aggregated, opt-in screen-time report (for the "scroll vs sweat" chart).
create table screen_time_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  report_date date not null,
  blocked_minutes int not null,
  by_category jsonb not null default '{}'::jsonb,
  unique (user_id, report_date)
);

-- Social (v1.5) ---------------------------------------------------------

create type friendship_status as enum ('pending', 'accepted', 'blocked');

create table friendships (
  user_id uuid not null references users(id) on delete cascade,
  friend_id uuid not null references users(id) on delete cascade,
  status friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id)
);

create table crews (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table crew_members (
  crew_id uuid not null references crews(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (crew_id, user_id)
);

create table feed_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  type text not null,                      -- streak, challenge_done, emergency_key...
  payload jsonb not null default '{}'::jsonb,
  visibility text not null default 'friends' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz not null default now()
);

-- RLS: everything private by default; owners read/write their own rows.
alter table users enable row level security;
alter table gyms enable row level security;
alter table block_profiles enable row level security;
alter table gym_sessions enable row level security;
alter table workouts enable row level security;
alter table challenge_completions enable row level security;
alter table unlocks enable row level security;
alter table screen_time_reports enable row level security;
alter table friendships enable row level security;
alter table feed_events enable row level security;

create policy "own rows" on gyms for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own rows" on block_profiles for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own rows" on gym_sessions for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own rows" on workouts for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own rows" on unlocks for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own rows" on screen_time_reports for all
  using (user_id = (select id from users where auth_id = auth.uid()));
create policy "own profile" on users for all using (auth_id = auth.uid());
-- Friend-visible feed policies land with the social release (v1.5).
