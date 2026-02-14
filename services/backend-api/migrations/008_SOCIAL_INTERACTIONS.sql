-- APPEND TO EXISTING SCHEMA

-- 10. Social Interactions (Likes & Comments)
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
    created_at timestamptz DEFAULT now()
);

-- RLS
ALTER TABLE public.trace_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trace_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public likes read" ON public.trace_likes FOR SELECT USING (true);
CREATE POLICY "Auth likes write" ON public.trace_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Auth likes delete" ON public.trace_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Public comments read" ON public.trace_comments FOR SELECT USING (true);
CREATE POLICY "Auth comments write" ON public.trace_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
