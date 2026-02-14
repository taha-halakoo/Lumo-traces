-- 005_GAMIFICATION.sql

-- 1. Badges System
CREATE TABLE IF NOT EXISTS public.badges (
    id text PRIMARY KEY, -- e.g., 'explorer_lvl_1'
    name text NOT NULL,
    description text NOT NULL,
    icon_url text NOT NULL,
    criteria jsonb NOT NULL -- e.g., {"min_traces": 10}
);

CREATE TABLE IF NOT EXISTS public.user_badges (
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_id text REFERENCES public.badges(id) ON DELETE CASCADE,
    earned_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, badge_id)
);

-- 2. Leaderboard View (Real-time calculation)
-- Optimized for speed: Only shows Top 100
CREATE OR REPLACE VIEW public.leaderboard_global AS
SELECT 
    id as user_id,
    username,
    avatar_url,
    reputation_points,
    RANK() OVER (ORDER BY reputation_points DESC) as rank
FROM public.profiles
WHERE reputation_points > 0
LIMIT 100;

-- 3. Parasitic State Table (Active Infections)
CREATE TABLE IF NOT EXISTS public.parasitic_infections (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id) NOT NULL,
    trace_id uuid REFERENCES public.traces(id) NOT NULL,
    infected_at timestamptz DEFAULT now(),
    origin_lat float NOT NULL,
    origin_long float NOT NULL,
    cure_distance_km float DEFAULT 1.0,
    is_cured boolean DEFAULT false,
    cured_at timestamptz
);
