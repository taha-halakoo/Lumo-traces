-- 12. Feature Flags
CREATE TABLE IF NOT EXISTS public.feature_flags (
    key text PRIMARY KEY,
    is_enabled boolean DEFAULT false,
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read flags" ON public.feature_flags FOR SELECT USING (true);

-- Seed Default Flags
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
