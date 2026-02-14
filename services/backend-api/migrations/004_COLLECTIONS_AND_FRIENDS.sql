-- 004_COLLECTIONS_AND_FRIENDS.sql

-- 1. Collections Table (Curated sets of traces)
CREATE TABLE IF NOT EXISTS public.collections (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.profiles(id) NOT NULL,
  title text NOT NULL,
  description text,
  is_public boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 2. Collection Items (Link Traces to Collections)
CREATE TABLE IF NOT EXISTS public.collection_items (
  collection_id uuid REFERENCES public.collections(id) ON DELETE CASCADE,
  trace_id uuid REFERENCES public.traces(id) ON DELETE CASCADE,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (collection_id, trace_id)
);

-- 3. Update the Hybrid Search to BOOST Friends
-- We replace the previous function to add the Friend Logic
CREATE OR REPLACE FUNCTION get_traces_hybrid(
  user_lat float,
  user_long float,
  radius_meters float,
  mood_vector vector(384),
  identity_vector vector(384),
  requesting_user_id uuid -- NEW: We need to know WHO is asking to check friends
)
RETURNS TABLE (
  id uuid,
  author_id uuid, -- ADDED
  type public.trace_type,
  lat float,
  long float,
  content_text text,
  media_url text,
  hashtags text[], -- ADDED
  created_at timestamptz, -- ADDED
  expires_at timestamptz, -- ADDED
  music_track_id text, -- ADDED
  author_username text, 
  is_friend boolean,    
  score float
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.author_id, -- ADDED
    t.type,
    ST_Y(t.location::geometry) as lat,
    ST_X(t.location::geometry) as long,
    t.content_text,
    t.media_url,
    t.hashtags, -- ADDED
    t.created_at, -- ADDED
    t.expires_at, -- ADDED
    t.music_track_id, -- ADDED
    p.username as author_username,
    -- Check Friendship Status
    EXISTS (
        SELECT 1 FROM public.friendships f 
        WHERE (f.user_id_1 = requesting_user_id AND f.user_id_2 = t.author_id)
           OR (f.user_id_1 = t.author_id AND f.user_id_2 = requesting_user_id)
        AND f.status = 'accepted'
    ) as is_friend,
    (
      -- WEIGHTED SCORING ALGORITHM
      -- 1. Mood Match (50%)
      ((1 - (t.embedding <=> mood_vector)) * 0.5) +
      -- 2. Identity Match (20%)
      ((1 - (t.embedding <=> identity_vector)) * 0.2) +
      -- 3. Recency (10%)
      (GREATEST(0, 1 - (EXTRACT(EPOCH FROM (now() - t.created_at)) / 172800)) * 0.1)
      -- 4. FRIEND BOOST (Hard +0.3 boost)
      + (CASE WHEN EXISTS (
            SELECT 1 FROM public.friendships f 
            WHERE (f.user_id_1 = requesting_user_id AND f.user_id_2 = t.author_id)
               OR (f.user_id_1 = t.author_id AND f.user_id_2 = requesting_user_id)
            AND f.status = 'accepted'
         ) THEN 0.3 ELSE 0 END)
      -- 5. TYPE MULTIPLIERS
      * (CASE WHEN t.type = 'ORB' THEN 1.5 
              WHEN t.type = 'CHALLENGE' THEN 1.2 
              ELSE 1.0 END)
    )::float as score
  FROM 
    public.traces t
  JOIN
    public.profiles p ON t.author_id = p.id
  WHERE 
    ST_DWithin(
      t.location,
      ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326),
      radius_meters
    )
    AND (t.expires_at IS NULL OR t.expires_at > now())
  ORDER BY 
    score DESC
  LIMIT 50;
END;
$$;