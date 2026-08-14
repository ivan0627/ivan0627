-- Lockout — emergency keys + strict mode server rules (PLAN.md §3.2)
-- Remaining keys are DERIVED from unlocks (quota minus this month's usage),
-- never a mutable counter that can drift from the evidence.

alter table block_profiles
  rename column emergency_keys_left to emergency_keys_quota;
alter table block_profiles
  alter column emergency_keys_quota set default 3;

create or replace function emergency_keys_used_this_month(uid uuid)
returns int language sql stable as $$
  select count(*)::int
  from unlocks
  where user_id = uid
    and granted_by = 'emergency_key'
    and granted_at >= date_trunc('month', now());
$$;

-- The escape hatch: limited per month, 24 h cooldown, and (opt-in) visible to
-- your crew. Returns {granted, remaining, reason?, expires_at?}.
create or replace function use_emergency_key(uid uuid)
returns jsonb
language plpgsql as $$
declare
  quota int;
  used int;
  last_used timestamptz;
  reward_hours int;
  expires timestamptz;
  share boolean;
begin
  select bp.emergency_keys_quota, bp.reward_hours
    into quota, reward_hours
  from block_profiles bp where bp.user_id = uid
  limit 1;
  if quota is null then
    return jsonb_build_object('granted', false, 'reason', 'no_profile');
  end if;

  used := emergency_keys_used_this_month(uid);
  if used >= quota then
    return jsonb_build_object('granted', false, 'reason', 'quota_exhausted',
                              'remaining', 0);
  end if;

  select max(granted_at) into last_used
  from unlocks where user_id = uid and granted_by = 'emergency_key';
  if last_used is not null and last_used > now() - interval '24 hours' then
    return jsonb_build_object('granted', false, 'reason', 'cooldown',
                              'remaining', quota - used,
                              'retry_at', last_used + interval '24 hours');
  end if;

  expires := case
    when coalesce(reward_hours, 0) > 0 then now() + (reward_hours || ' hours')::interval
    else date_trunc('day', now()) + interval '23 hours 59 minutes'
  end;

  insert into unlocks (user_id, granted_by, expires_at)
  values (uid, 'emergency_key', expires);

  -- Social accountability: only if the user opted in (settings.share_emergency_keys).
  select coalesce((u.settings ->> 'share_emergency_keys')::boolean, false)
    into share from users u where u.id = uid;
  if share then
    insert into feed_events (user_id, type, payload, visibility)
    values (uid, 'emergency_key_used',
            jsonb_build_object('remaining', quota - used - 1), 'friends');
  end if;

  return jsonb_build_object('granted', true,
                            'remaining', quota - used - 1,
                            'expires_at', expires);
end;
$$;

-- Strict mode: the client asks the server before allowing ANY loosening
-- (disable blocking, remove an app, extend reward). One source of truth.
create or replace function can_modify_blocking(uid uuid)
returns jsonb language sql stable as $$
  select case
    when bp.strict_until is not null and bp.strict_until > now()
      then jsonb_build_object('allowed', false, 'strict_until', bp.strict_until)
    else jsonb_build_object('allowed', true)
  end
  from block_profiles bp where bp.user_id = uid
  limit 1;
$$;
