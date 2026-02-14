-- 007_AUTO_TIMESTAMP.sql

-- Trigger to automatically update 'last_mood_update' whenever 'mood_embedding' changes
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
