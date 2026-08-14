-- Test suite for 0003: emergency keys + strict mode
\set ON_ERROR_STOP on
begin;

insert into users (id, auth_id, handle, settings) values
  ('00000000-0000-0000-0000-00000000000a', gen_random_uuid(), 'keys_user',
   '{"share_emergency_keys": true}'::jsonb);
insert into block_profiles (user_id, platform, emergency_keys_quota) values
  ('00000000-0000-0000-0000-00000000000a', 'ios', 2);

-- T1: first key granted, remaining drops to 1
select 'T1 first key granted' as test,
  (use_emergency_key('00000000-0000-0000-0000-00000000000a') ->> 'granted')::boolean
  = true as pass;

select 'T2 remaining derived from unlocks' as test,
  emergency_keys_used_this_month('00000000-0000-0000-0000-00000000000a') = 1 as pass;

-- T3: second key within 24 h → cooldown
select 'T3 cooldown blocks back-to-back keys' as test,
  (use_emergency_key('00000000-0000-0000-0000-00000000000a') ->> 'reason')
  = 'cooldown' as pass;

-- T4: opted-in usage produced a crew-visible feed event
select 'T4 feed event on opt-in' as test,
  exists (select 1 from feed_events
          where user_id = '00000000-0000-0000-0000-00000000000a'
            and type = 'emergency_key_used' and visibility = 'friends') as pass;

-- T5: quota exhaustion (backdate first key past cooldown, burn the second)
update unlocks set granted_at = now() - interval '25 hours'
  where user_id = '00000000-0000-0000-0000-00000000000a';
select use_emergency_key('00000000-0000-0000-0000-00000000000a') \gset second_
update unlocks set granted_at = now() - interval '25 hours'
  where user_id = '00000000-0000-0000-0000-00000000000a';
select 'T5 quota exhausted after 2 keys' as test,
  (use_emergency_key('00000000-0000-0000-0000-00000000000a') ->> 'reason')
  = 'quota_exhausted' as pass;

-- T6: no opt-in → no feed event
insert into users (id, auth_id, handle) values
  ('00000000-0000-0000-0000-00000000000b', gen_random_uuid(), 'private_user');
insert into block_profiles (user_id, platform) values
  ('00000000-0000-0000-0000-00000000000b', 'android');
select use_emergency_key('00000000-0000-0000-0000-00000000000b') \gset private_
select 'T6 no feed event without opt-in' as test,
  not exists (select 1 from feed_events
              where user_id = '00000000-0000-0000-0000-00000000000b') as pass;

-- T7: strict mode blocks loosening until strict_until
update block_profiles set strict_until = now() + interval '7 days'
  where user_id = '00000000-0000-0000-0000-00000000000b';
select 'T7 strict mode locks settings' as test,
  (can_modify_blocking('00000000-0000-0000-0000-00000000000b') ->> 'allowed')::boolean
  = false as pass;

-- T8: expired strict mode allows changes again
update block_profiles set strict_until = now() - interval '1 hour'
  where user_id = '00000000-0000-0000-0000-00000000000b';
select 'T8 expired strict mode unlocks settings' as test,
  (can_modify_blocking('00000000-0000-0000-0000-00000000000b') ->> 'allowed')::boolean
  = true as pass;

rollback;
