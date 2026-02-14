-- 002_VECTOR_AND_TYPES.sql

-- Enable vector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Define Trace Types
CREATE TYPE public.trace_type AS ENUM ('STANDARD', 'STORY', 'CHALLENGE', 'ORB', 'FRIEND');

-- Update Traces Table
ALTER TABLE public.traces 
  ADD COLUMN IF NOT EXISTS type public.trace_type DEFAULT 'STANDARD',
  ADD COLUMN IF NOT EXISTS embedding vector(384), -- Using 384 dimensions (common for light mobile models)
  ADD COLUMN IF NOT EXISTS hashtags text[],
  ADD COLUMN IF NOT EXISTS media_url text, -- For the Insta-story background
  ADD COLUMN IF NOT EXISTS music_track_id text; -- For the song suggestion

-- Migrate existing boolean flags to the new Enum
UPDATE public.traces SET type = 'STORY' WHERE is_story = true;
UPDATE public.traces SET type = 'ORB' WHERE is_gold = true;
-- (Assuming 'Friends' logic was dynamic, but if stored, we'd update here)

-- Drop old boolean columns after data is safe (optional, keeping for safety for now)
-- ALTER TABLE public.traces DROP COLUMN is_story;
-- ALTER TABLE public.traces DROP COLUMN is_gold;

-- Update Profiles Table for the "Dual Vector" Brain
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS identity_embedding vector(384), -- Long-term "Who I am"
  ADD COLUMN IF NOT EXISTS mood_embedding vector(384),     -- Short-term "What I want now"
  ADD COLUMN IF NOT EXISTS last_mood_update timestamptz DEFAULT now();

-- Create an index for fast similarity search
CREATE INDEX ON public.traces USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
