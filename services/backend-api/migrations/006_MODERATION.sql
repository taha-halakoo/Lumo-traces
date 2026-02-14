-- 006_MODERATION.sql

-- 1. Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.profiles(id),
    trace_id uuid REFERENCES public.traces(id),
    reason text NOT NULL, -- e.g., 'spam', 'offensive', 'fake'
    created_at timestamptz DEFAULT now(),
    status text DEFAULT 'pending' -- 'pending', 'resolved', 'dismissed'
);

-- 2. Add 'is_hidden' to Traces for moderation
ALTER TABLE public.traces 
ADD COLUMN IF NOT EXISTS is_hidden boolean DEFAULT false;

-- 3. Auto-Moderation Trigger
-- If a trace gets 5 unique reports, hide it automatically
CREATE OR REPLACE FUNCTION check_auto_mod()
RETURNS TRIGGER AS $$
DECLARE
    report_count int;
BEGIN
    SELECT count(*) INTO report_count 
    FROM public.reports 
    WHERE trace_id = NEW.trace_id;

    IF report_count >= 5 THEN
        UPDATE public.traces SET is_hidden = true WHERE id = NEW.trace_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_mod
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION check_auto_mod();

-- 4. Update Notifications Schema (If not fully robust)
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id),
    type text NOT NULL, -- 'badge', 'friend_trace', 'infection', 'system'
    title text NOT NULL,
    body text,
    data jsonb, -- e.g. { "trace_id": "..." }
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);
