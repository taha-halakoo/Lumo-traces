-- TRACES MASTER SCHEMA (Consolidated & Clean Slate)
-- WARNING: This script WIPES the database before rebuilding it.

-- 0. THE NUCLEAR OPTION (Cleanup)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_profile_created_settings ON public.profiles;
DROP FUNCTION IF EXISTS public.handle_new_user;
DROP FUNCTION IF EXISTS public.handle_new_user_settings;

DROP TRIGGER IF EXISTS trigger_auto_mod ON public.reports;
DROP TRIGGER IF EXISTS trigger_update_mood_ts ON public.profiles;

DROP FUNCTION IF EXISTS get_traces_hybrid;
DROP FUNCTION IF EXISTS update_mood_timestamp;
DROP FUNCTION IF EXISTS check_auto_mod;
DROP FUNCTION IF EXISTS claim_gold_orb;
DROP FUNCTION IF EXISTS check_distance;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.trace_comments CASCADE;
DROP TABLE IF EXISTS public.trace_likes CASCADE;
DROP TABLE IF EXISTS public.parasitic_infections CASCADE;
DROP TABLE IF EXISTS public.user_badges CASCADE;
DROP TABLE IF EXISTS public.badges CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.collection_items CASCADE;
DROP TABLE IF EXISTS public.collections CASCADE;
DROP TABLE IF EXISTS public.unlocked_traces CASCADE;
DROP TABLE IF EXISTS public.trackers CASCADE;
DROP TABLE IF EXISTS public.friendships CASCADE;
DROP TABLE IF EXISTS public.traces CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.feature_flags CASCADE;

DROP TYPE IF EXISTS public.trace_type CASCADE;

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Profiles Table (Users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username text UNIQUE,
    full_name text,
    avatar_url text,
    reputation_points int DEFAULT 0,
    -- Extended Profile
    birthdate date,
    bio text,
    personality_type text,
    interests_graph jsonb DEFAULT '{}',
    -- Brain Vectors
    identity_embedding vector(384),
    mood_embedding vector(384),
    last_mood_update timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
---
-- Interest Decay (RPC)
CREATE OR REPLACE FUNCTION decay_all_interests(decay_factor float DEFAULT 0.95)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Multiplies all values in the jsonb object by decay_factor
  UPDATE public.profiles
  SET interests_graph = (
    SELECT jsonb_object_agg(key, (value::float * decay_factor)::int)
    FROM jsonb_each(interests_graph)
  )
  WHERE interests_graph IS DISTINCT FROM '{}'::jsonb;
END;
$$;


-- 3. Trace Types
CREATE TYPE public.trace_type AS ENUM ('STANDARD', 'STORY', 'CHALLENGE', 'ORB', 'FRIEND');

-- 4. Traces Table (Content)
CREATE TABLE IF NOT EXISTS public.traces (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    author_id uuid REFERENCES public.profiles(id) NOT NULL,
    location geography(POINT) NOT NULL,
    type public.trace_type DEFAULT 'STANDARD',
    
    -- Content
    content_text text,
    content_url text,
    media_url text,
    music_track_id text,
    
    -- Metadata
    tags text[],
    hashtags text[],
    embedding vector(384),
    
    -- Visibility & Logic
    visibility text DEFAULT 'public', -- 'public', 'friends', 'private'
    is_hidden boolean DEFAULT false, -- Moderation
    
    -- Game Logic
    max_claims int,
    current_claims int DEFAULT 0,
    
    -- Time
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    expires_at timestamptz, -- For Stories
    deleted_at timestamptz -- Soft delete
);

-- Index for Hybrid Search
CREATE INDEX ON public.traces USING GIST (location);
CREATE INDEX ON public.traces USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 5. Social Tables
CREATE TABLE IF NOT EXISTS public.friendships (
    user_id_1 uuid REFERENCES public.profiles(id),
    user_id_2 uuid REFERENCES public.profiles(id),
    status text DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id_1, user_id_2)
);

CREATE TABLE IF NOT EXISTS public.trackers (
    tracker_id uuid REFERENCES public.profiles(id),
    target_id uuid REFERENCES public.profiles(id),
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (tracker_id, target_id)
);

CREATE TABLE IF NOT EXISTS public.trace_likes (
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    trace_id uuid REFERENCES public.traces(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, trace_id)
);

CREATE TABLE IF NOT EXISTS public.trace_comments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    trace_id uuid REFERENCES public.traces(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    deleted_at timestamptz
);

-- 6. Interaction Tables
CREATE TABLE IF NOT EXISTS public.unlocked_traces (
    user_id uuid REFERENCES public.profiles(id),
    trace_id uuid REFERENCES public.traces(id),
    unlocked_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, trace_id)
);

CREATE TABLE IF NOT EXISTS public.collections (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.profiles(id) NOT NULL,
  title text NOT NULL,
  description text,
  is_public boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.collection_items (
  collection_id uuid REFERENCES public.collections(id) ON DELETE CASCADE,
  trace_id uuid REFERENCES public.traces(id) ON DELETE CASCADE,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (collection_id, trace_id)
);

CREATE TABLE IF NOT EXISTS public.reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.profiles(id),
    trace_id uuid REFERENCES public.traces(id),
    reason text NOT NULL, 
    created_at timestamptz DEFAULT now(),
    status text DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id),
    type text NOT NULL,
    title text NOT NULL,
    body text,
    data jsonb,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id),
    action text NOT NULL,
    table_name text,
    record_id uuid,
    details jsonb,
    ip_address text,
    created_at timestamptz DEFAULT now()
);

-- 7. Gamification Tables
-- ...

-- 7.5 User Settings
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    push_notifications boolean DEFAULT true,
    email_notifications boolean DEFAULT true,
    location_sharing boolean DEFAULT true,
    incognito_mode boolean DEFAULT false,
    sound_effects boolean DEFAULT true,
    haptic_enabled boolean DEFAULT true,
    auto_unlock_range int DEFAULT 20, -- meters
    theme_mode text DEFAULT 'liquid_dark',
    updated_at timestamptz DEFAULT now()
);

-- 7.6 Feature Flags
CREATE TABLE IF NOT EXISTS public.feature_flags (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    key text UNIQUE NOT NULL,
    is_enabled boolean DEFAULT false,
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 8. Functions & Triggers

-- AUTO PROFILE CREATION (CRITICAL FOR AUTH)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url, birthdate, bio, personality_type)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', 'https://api.dicebear.com/7.x/bottts/svg?seed=' || NEW.id),
    (NEW.raw_user_meta_data->>'birthdate')::date,
    NEW.raw_user_meta_data->>'bio',
    NEW.raw_user_meta_data->>'personality_type'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-create settings on profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_created_settings
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_settings();

-- Secure Distance Check
CREATE OR REPLACE FUNCTION check_distance(trace_id uuid, user_lat float, user_long float)
RETURNS TABLE (unlocked boolean, distance_meters float) 
LANGUAGE plpgsql
AS $$
DECLARE
    trace_loc geography;
BEGIN
    SELECT location INTO trace_loc FROM public.traces WHERE id = trace_id;
    
    IF trace_loc IS NULL THEN
        RETURN QUERY SELECT false, 0.0::float;
        RETURN;
    END IF;

    distance_meters := ST_Distance(trace_loc, ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326));
    
    IF distance_meters < 20 THEN
        RETURN QUERY SELECT true, distance_meters;
    ELSE
        RETURN QUERY SELECT false, distance_meters;
    END IF;
END;
$$;

-- Claim Gold Orb (Transactional)
CREATE OR REPLACE FUNCTION claim_gold_orb(trace_id_input uuid, user_id_input uuid, lat_input float, long_input float)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    trace_record record;
    dist float;
BEGIN
    SELECT * INTO trace_record FROM public.traces WHERE id = trace_id_input FOR UPDATE;
    
    IF trace_record.type != 'ORB' THEN RETURN NULL; END IF;
    IF trace_record.current_claims >= trace_record.max_claims THEN RETURN NULL; END IF;

    dist := ST_Distance(trace_record.location, ST_SetSRID(ST_MakePoint(long_input, lat_input), 4326));
    IF dist > 20 THEN RETURN NULL; END IF;

    UPDATE public.traces 
    SET current_claims = current_claims + 1 
    WHERE id = trace_id_input;

    UPDATE public.profiles 
    SET reputation_points = reputation_points + 50 
    WHERE id = user_id_input;

    INSERT INTO public.unlocked_traces (user_id, trace_id) 
    VALUES (user_id_input, trace_id_input) 
    ON CONFLICT DO NOTHING;

    RETURN json_build_object('reward', 50, 'claims_left', trace_record.max_claims - (trace_record.current_claims + 1));
END;
$$;

-- Auto-Moderation
CREATE OR REPLACE FUNCTION check_auto_mod()
RETURNS TRIGGER AS $$
DECLARE
    report_count int;
BEGIN
    SELECT count(*) INTO report_count FROM public.reports WHERE trace_id = NEW.trace_id;
    IF report_count >= 5 THEN
        UPDATE public.traces SET is_hidden = true WHERE id = NEW.trace_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_mod
AFTER INSERT ON public.reports
FOR EACH ROW EXECUTE FUNCTION check_auto_mod();

-- Mood Timestamp
CREATE OR REPLACE FUNCTION update_mood_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_mood_update = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_mood_ts
BEFORE UPDATE ON public.profiles
FOR EACH ROW
WHEN (OLD.mood_embedding IS DISTINCT FROM NEW.mood_embedding)
EXECUTE FUNCTION update_mood_timestamp();

-- THE SMART BRAIN (Hybrid Search)
CREATE OR REPLACE FUNCTION get_traces_hybrid(
  user_lat float,
  user_long float,
  radius_meters float,
  mood_vector vector(384),
  identity_vector vector(384),
  requesting_user_id uuid
)
RETURNS TABLE (
  id uuid,
  author_id uuid,
  type public.trace_type,
  lat float,
  long float,
  content_text text,
  media_url text,
  hashtags text[],
  created_at timestamptz,
  expires_at timestamptz,
  music_track_id text,
  profiles jsonb, -- Return profile as JSON to match other queries
  is_friend boolean,    
  score float
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.author_id,
    t.type,
    ST_Y(t.location::geometry) as lat,
    ST_X(t.location::geometry) as long,
    t.content_text,
    t.media_url,
    t.hashtags,
    t.created_at,
    t.expires_at,
    t.music_track_id,
    jsonb_build_object(
      'username', p.username,
      'avatar_url', p.avatar_url
    ) as profiles,
    EXISTS (
        SELECT 1 FROM public.friendships f 
        WHERE (f.user_id_1 = requesting_user_id AND f.user_id_2 = t.author_id)
           OR (f.user_id_1 = t.author_id AND f.user_id_2 = requesting_user_id)
        AND f.status = 'accepted'
    ) as is_friend,
    (
      ((1 - (t.embedding <=> mood_vector)) * 0.5) +
      ((1 - (t.embedding <=> identity_vector)) * 0.2) +
      (GREATEST(0, 1 - (EXTRACT(EPOCH FROM (now() - t.created_at)) / 172800)) * 0.1)
      + (CASE WHEN EXISTS (
            SELECT 1 FROM public.friendships f 
            WHERE (f.user_id_1 = requesting_user_id AND f.user_id_2 = t.author_id)
               OR (f.user_id_1 = t.author_id AND f.user_id_2 = requesting_user_id)
        AND f.status = 'accepted'
         ) THEN 0.3 ELSE 0 END)
      * (CASE WHEN t.type = 'ORB' THEN 1.5 
              WHEN t.type = 'CHALLENGE' THEN 1.2 
              ELSE 1.0 END)
    )::float as score
  FROM 
    public.traces t
  JOIN
    public.profiles p ON t.author_id = p.id
  JOIN
    public.user_settings s ON p.id = s.user_id
  WHERE 
    ST_DWithin(
      t.location,
      ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326),
      radius_meters
    )
    AND (t.expires_at IS NULL OR t.expires_at > now())
    AND t.is_hidden = false
    AND t.deleted_at IS NULL
    AND s.incognito_mode = false -- Hide traces from incognito users
  ORDER BY 
    score DESC
  LIMIT 50;
END;
$$;

-- Weekly Leaderboard (Approximate based on recent activity)
CREATE OR REPLACE FUNCTION get_weekly_leaderboard(
  scope text DEFAULT 'global',
  requesting_user_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  username text,
  avatar_url text,
  reputation_points bigint -- Calculated weekly score
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.avatar_url,
    (
      -- Count unlocked traces (50 pts each)
      (SELECT count(*) FROM public.unlocked_traces u 
       WHERE u.user_id = p.id AND u.unlocked_at > now() - interval '7 days') * 50
      +
      -- Count traces dropped (10 pts each - assumed)
      (SELECT count(*) FROM public.traces t 
       WHERE t.author_id = p.id AND t.created_at > now() - interval '7 days') * 10
    )::bigint as weekly_score
  FROM 
    public.profiles p
  JOIN
    public.user_settings s ON p.id = s.user_id
  WHERE 
    s.incognito_mode = false
    AND (
      scope = 'global' 
      OR 
      (scope = 'friends' AND EXISTS (
        SELECT 1 FROM public.friendships f 
        WHERE (f.user_id_1 = requesting_user_id AND f.user_id_2 = p.id)
           OR (f.user_id_1 = p.id AND f.user_id_2 = requesting_user_id)
        AND f.status = 'accepted'
      ))
    )
  ORDER BY 
    weekly_score DESC
  LIMIT 50;
END;
$$;

-- 9. Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.traces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trace_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trace_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

-- Profiles: Public Read, Self Update
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Traces: Public Read (if not deleted), Auth Create
CREATE POLICY "Traces are viewable by everyone" 
ON public.traces FOR SELECT USING (deleted_at IS NULL AND is_hidden = false);

CREATE POLICY "Users can create traces" 
ON public.traces FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can soft delete own traces"
ON public.traces FOR UPDATE USING (auth.uid() = author_id);

-- Settings
CREATE POLICY "Users can manage own settings" ON public.user_settings FOR ALL USING (auth.uid() = user_id);

-- Likes
CREATE POLICY "Public likes read" ON public.trace_likes FOR SELECT USING (true);
CREATE POLICY "Auth likes write" ON public.trace_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Auth likes delete" ON public.trace_likes FOR DELETE USING (auth.uid() = user_id);

-- Comments
CREATE POLICY "Public comments read" ON public.trace_comments FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "Auth comments write" ON public.trace_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.trace_comments FOR UPDATE USING (auth.uid() = user_id);

-- Audit Logs
CREATE POLICY "Admins read logs" ON public.audit_logs FOR SELECT USING (false); -- Locked down

-- Feature Flags
CREATE POLICY "Public read flags" ON public.feature_flags FOR SELECT USING (true);

-- 12. Feature Flags Seed
INSERT INTO public.feature_flags (key, is_enabled, description) VALUES
('ar_scanner', true, 'Enable AR Reality features'),
('chat_system', true, 'Enable Neural Link Chat'),
('social_graph', true, 'Enable Friends and Leaderboard'),
('inventory_crafting', false, 'Enable Item Crafting (Coming Soon)')
ON CONFLICT (key) DO NOTHING;

-- 13. Auto-Update Timestamp Function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to critical tables
DROP TRIGGER IF EXISTS update_profiles_modtime ON public.profiles;
CREATE TRIGGER update_profiles_modtime BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_traces_modtime ON public.traces;
CREATE TRIGGER update_traces_modtime BEFORE UPDATE ON public.traces FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_flags_modtime ON public.feature_flags;
CREATE TRIGGER update_flags_modtime BEFORE UPDATE ON public.feature_flags FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
