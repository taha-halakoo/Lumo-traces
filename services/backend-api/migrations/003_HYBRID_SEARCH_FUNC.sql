-- 003_HYBRID_SEARCH_FUNC.sql

-- A "Wise" Search function that combines:
-- 1. Physical Location (Hard Constraint)
-- 2. Vector Similarity (Soft Constraint - Mood & Identity)
-- 3. Time Decay (Recency)

CREATE OR REPLACE FUNCTION get_traces_hybrid(
  user_lat float,
  user_long float,
  radius_meters float,
  mood_vector vector(384),
  identity_vector vector(384)
)
RETURNS TABLE (
  id uuid,
  type public.trace_type,
  lat float,
  long float,
  content_text text,
  media_url text,
  score float
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.type,
    ST_Y(t.location::geometry) as lat,
    ST_X(t.location::geometry) as long,
    t.content_text,
    t.media_url,
    (
      -- WEIGHTED SCORING ALGORITHM IN SQL
      -- 1. Mood Match (60%)
      ((1 - (t.embedding <=> mood_vector)) * 0.6) +
      -- 2. Identity Match (20%)
      ((1 - (t.embedding <=> identity_vector)) * 0.2) +
      -- 3. Recency Boost (20%) - linearly decays over 48 hours
      (GREATEST(0, 1 - (EXTRACT(EPOCH FROM (now() - t.created_at)) / 172800)) * 0.2)
      -- 4. Bonus for ORBS (Multiplying the whole score)
      * (CASE WHEN t.type = 'ORB' THEN 1.5 ELSE 1.0 END)
    )::float as score
  FROM 
    public.traces t
  WHERE 
    -- THE LAWS OF PHYSICS (Hard Constraint)
    ST_DWithin(
      t.location,
      ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326),
      radius_meters
    )
    AND (t.expires_at IS NULL OR t.expires_at > now()) -- Don't show dead stories
  ORDER BY 
    score DESC
  LIMIT 50; -- Efficiency: Only return the best 50
END;
$$;
