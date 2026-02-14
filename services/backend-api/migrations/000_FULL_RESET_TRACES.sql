-- ==============================================================================
-- TRACES: MASTER RESET SCRIPT (FIXED PARAMETERS)
-- WARNING: THIS WILL WIPE ALL DATA IN THE PUBLIC SCHEMA.
-- DATE: 2026-02-06
-- ==============================================================================

-- 1. CLEANUP (Drop Everything)
drop trigger if exists tr_notify_friend_request on public.friendships;
drop function if exists notify_on_friend_request;
drop function if exists cleanup_expired_traces;
drop function if exists report_trace;
drop function if exists claim_gold_orb;
drop function if exists check_distance;
drop function if exists get_traces_nearby_v3;
drop function if exists get_traces_nearby_v2;
drop function if exists get_traces_nearby;

drop table if exists public.notifications cascade;
drop table if exists public.reports cascade;
drop table if exists public.trace_likes cascade;
drop table if exists public.saved_traces cascade;
drop table if exists public.trackers cascade;
drop table if exists public.user_unlocks cascade;
drop table if exists public.friendships cascade;
drop table if exists public.traces cascade;
drop table if exists public.profiles cascade;

-- Enable PostGIS
create extension if not exists postgis;

-- ==============================================================================
-- 2. TABLES
-- ==============================================================================

-- A. PROFILES
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  avatar_url text,
  reputation_points int default 100,
  interests_graph jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- B. TRACES
create table public.traces (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  location geography(POINT) not null,
  content_type text check (content_type in ('text', 'image', 'audio', 'video')),
  content_url text,
  text_content text,
  is_gold boolean default false,
  is_story boolean default false,
  max_claims int default 1,
  current_claims int default 0,
  visibility text check (visibility in ('public', 'friends', 'trackers', 'private')) default 'public',
  unlock_radius_meters int default 20,
  expires_at timestamp with time zone,
  tags text[] default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
create index traces_geo_index on public.traces using GIST (location);

-- C. FRIENDSHIPS
create table public.friendships (
  id uuid default gen_random_uuid() primary key,
  user_a uuid references public.profiles(id) not null,
  user_b uuid references public.profiles(id) not null,
  status text check (status in ('pending', 'accepted', 'blocked')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_a, user_b)
);
create index idx_friendships_a on public.friendships(user_a);
create index idx_friendships_b on public.friendships(user_b);

-- D. TRACKERS
create table public.trackers (
  id uuid default gen_random_uuid() primary key,
  tracker_id uuid references public.profiles(id) not null,
  target_id uuid references public.profiles(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(tracker_id, target_id)
);

-- E. UNLOCKS
create table public.user_unlocks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  trace_id uuid references public.traces(id) not null,
  unlocked_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, trace_id)
);

-- F. NOTIFICATIONS
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  type text check (type in ('friend_request', 'trace_unlocked', 'trace_reported', 'gold_reward')),
  title text not null,
  body text,
  data jsonb default '{}'::jsonb,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- G. REPORTS
create table public.reports (
  id uuid default gen_random_uuid() primary key,
  reporter_id uuid references public.profiles(id) not null,
  trace_id uuid references public.traces(id) not null,
  reason text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(reporter_id, trace_id)
);

-- H. SAVED & LIKES
create table public.saved_traces (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  trace_id uuid references public.traces(id) not null,
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, trace_id)
);

create table public.trace_likes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  trace_id uuid references public.traces(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, trace_id)
);

-- ==============================================================================
-- 3. FUNCTIONS (LOGIC LAYER)
-- ==============================================================================

-- A. GET NEARBY TRACES (V3 - FIXED PARAMS)
create or replace function get_traces_nearby_v3(
  param_lat float,
  param_long float,
  param_radius int,
  param_user_id uuid
)
returns table (
  id uuid,
  lat float,
  long float,
  content_type text,
  is_gold boolean,
  is_story boolean,
  visibility text,
  distance_meters float,
  author_id uuid,
  expires_at timestamp with time zone
)
language plpgsql
security definer
as $$
begin
  return query
  select
    t.id,
    st_y(t.location::geometry) as lat,
    st_x(t.location::geometry) as long,
    t.content_type,
    t.is_gold,
    t.is_story,
    t.visibility,
    st_distance(t.location, st_point(param_long, param_lat)::geography) as distance_meters,
    t.user_id as author_id,
    t.expires_at
  from
    public.traces t
  where
    -- 1. Spatial Check
    st_dwithin(t.location, st_point(param_long, param_lat)::geography, param_radius)
    and (t.expires_at is null or t.expires_at > now())
    
    -- 2. Privacy Check
    and (
      -- Public
      t.visibility = 'public'
      -- Own
      or t.user_id = param_user_id
      -- Friends
      or (t.visibility = 'friends' and exists (
           select 1 from public.friendships f
           where f.status = 'accepted'
           and ((f.user_a = param_user_id and f.user_b = t.user_id) or (f.user_b = param_user_id and f.user_a = t.user_id))
      ))
      -- Trackers
      or (t.visibility = 'trackers' and exists (
           select 1 from public.trackers tr
           where tr.tracker_id = param_user_id
           and tr.target_id = t.user_id
      ))
    );
end;
$$;

-- B. CHECK DISTANCE (FIXED PARAMS)
create or replace function check_distance(
  param_trace_id uuid,
  param_user_lat float,
  param_user_long float
)
returns table (
  unlocked boolean,
  distance_meters float
)
language plpgsql
security definer
as $$
declare
  target_location geography;
  radius int;
  calc_dist float;
begin
  select location, unlock_radius_meters into target_location, radius
  from public.traces where id = param_trace_id;

  if not found then
    return query select false, 0.0;
    return;
  end if;

  calc_dist := st_distance(target_location, st_point(param_user_long, param_user_lat)::geography);

  if calc_dist <= radius then
    return query select true, calc_dist;
  else
    return query select false, calc_dist;
  end if;
end;
$$;

-- C. CLAIM GOLD ORB (FIXED PARAMS)
create or replace function claim_gold_orb(
  param_trace_id uuid,
  param_user_id uuid
)
returns table (
  success boolean,
  message text,
  reward_code text
)
language plpgsql
security definer
as $$
declare
  t_record record;
  already_claimed boolean;
begin
  -- Check Duplicate
  select exists(
    select 1 from public.user_unlocks 
    where user_unlocks.trace_id = param_trace_id 
    and user_unlocks.user_id = param_user_id
  ) into already_claimed;

  if already_claimed then
    return query select false, 'Already claimed.', null;
    return;
  end if;

  -- Lock Row
  select * into t_record from public.traces where id = param_trace_id for update;

  if not found or t_record.is_gold = false or t_record.current_claims >= t_record.max_claims then
    return query select false, 'Reward exhausted or invalid.', null;
    return;
  end if;

  -- Update
  update public.traces set current_claims = current_claims + 1 where id = param_trace_id;
  insert into public.user_unlocks (user_id, trace_id) values (param_user_id, param_trace_id);
  update public.profiles set reputation_points = reputation_points + 10 where id = param_user_id;

  return query select true, 'Claim successful!', t_record.text_content;
end;
$$;

-- D. REPORT SYSTEM (FIXED PARAMS)
create or replace function report_trace(
  param_trace_id uuid,
  param_reporter_id uuid,
  param_reason text
)
returns void
language plpgsql
security definer
as $$
declare
  report_count int;
  trace_owner_id uuid;
begin
  insert into public.reports (reporter_id, trace_id, reason) values (param_reporter_id, param_trace_id, param_reason);
  select count(*) into report_count from public.reports where reports.trace_id = param_trace_id;

  if report_count >= 5 then
    update public.traces set expires_at = now() where id = param_trace_id returning user_id into trace_owner_id;
    update public.profiles set reputation_points = reputation_points - 50 where id = trace_owner_id;
  end if;
end;
$$;

-- ==============================================================================
-- 4. TRIGGERS
-- ==============================================================================

create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

create or replace function notify_on_friend_request()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (
    new.user_b, 
    'friend_request', 
    'New Friend Request', 
    'Someone wants to see your private traces.', 
    jsonb_build_object('request_id', new.id, 'from_user', new.user_a)
  );
  return new;
end;
$$;

create trigger tr_notify_friend_request
after insert on public.friendships
for each row execute function notify_on_friend_request();

-- ==============================================================================
-- END OF SCRIPT
-- ==============================================================================