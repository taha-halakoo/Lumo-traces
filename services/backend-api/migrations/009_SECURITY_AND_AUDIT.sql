-- 11. Security & Audit
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

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read logs" ON public.audit_logs FOR SELECT USING (false); -- Locked down

-- Soft Delete Columns
ALTER TABLE public.traces ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
ALTER TABLE public.trace_comments ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Update Policies to exclude deleted
DROP POLICY IF EXISTS "Traces are viewable by everyone" ON public.traces;
CREATE POLICY "Traces are viewable by everyone" ON public.traces FOR SELECT USING (deleted_at IS NULL);
