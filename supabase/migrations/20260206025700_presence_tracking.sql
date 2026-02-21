-- Presence Tracking Migration
-- Adds real-time presence indicators, active annotators tracking, and sync status

-- 1. Types
DROP TYPE IF EXISTS public.presence_status CASCADE;
CREATE TYPE public.presence_status AS ENUM ('online', 'away', 'offline');

DROP TYPE IF EXISTS public.sync_status CASCADE;
CREATE TYPE public.sync_status AS ENUM ('connected', 'syncing', 'disconnected');

-- 2. Presence Tables
CREATE TABLE IF NOT EXISTS public.user_presence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.presence_status DEFAULT 'online'::public.presence_status,
    last_seen TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    current_document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.document_viewers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_annotating BOOLEAN DEFAULT false,
    UNIQUE(document_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.sync_status_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE,
    status public.sync_status NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_user_presence_user_id ON public.user_presence(user_id);
CREATE INDEX IF NOT EXISTS idx_user_presence_status ON public.user_presence(status);
CREATE INDEX IF NOT EXISTS idx_user_presence_document ON public.user_presence(current_document_id);
CREATE INDEX IF NOT EXISTS idx_document_viewers_document_id ON public.document_viewers(document_id);
CREATE INDEX IF NOT EXISTS idx_document_viewers_user_id ON public.document_viewers(user_id);
CREATE INDEX IF NOT EXISTS idx_document_viewers_last_active ON public.document_viewers(last_active DESC);
CREATE INDEX IF NOT EXISTS idx_sync_status_user_id ON public.sync_status_log(user_id);
CREATE INDEX IF NOT EXISTS idx_sync_status_document_id ON public.sync_status_log(document_id);

-- 4. Functions
CREATE OR REPLACE FUNCTION public.update_user_presence(
    p_user_id UUID,
    p_status public.presence_status,
    p_document_id UUID DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_presence (user_id, status, current_document_id, last_seen)
    VALUES (p_user_id, p_status, p_document_id, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
        status = EXCLUDED.status,
        current_document_id = EXCLUDED.current_document_id,
        last_seen = CURRENT_TIMESTAMP;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_document_viewing(
    p_document_id UUID,
    p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.document_viewers (document_id, user_id, last_active)
    VALUES (p_document_id, p_user_id, CURRENT_TIMESTAMP)
    ON CONFLICT (document_id, user_id)
    DO UPDATE SET
        last_active = CURRENT_TIMESTAMP,
        is_annotating = false;
    
    -- Update user presence
    PERFORM public.update_user_presence(p_user_id, 'online'::public.presence_status, p_document_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.leave_document_viewing(
    p_document_id UUID,
    p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.document_viewers
    WHERE document_id = p_document_id AND user_id = p_user_id;
    
    -- Update user presence
    PERFORM public.update_user_presence(p_user_id, 'online'::public.presence_status, NULL);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_annotating_status(
    p_document_id UUID,
    p_user_id UUID,
    p_is_annotating BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.document_viewers
    SET is_annotating = p_is_annotating, last_active = CURRENT_TIMESTAMP
    WHERE document_id = p_document_id AND user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_active_viewers(p_document_id UUID)
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    is_annotating BOOLEAN,
    last_active TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        dv.user_id,
        up.full_name,
        up.avatar_url,
        dv.is_annotating,
        dv.last_active
    FROM public.document_viewers dv
    JOIN public.user_profiles up ON dv.user_id = up.id
    WHERE dv.document_id = p_document_id
    AND dv.last_active > CURRENT_TIMESTAMP - INTERVAL '5 minutes'
    ORDER BY dv.last_active DESC;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_stale_viewers()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.document_viewers
    WHERE last_active < CURRENT_TIMESTAMP - INTERVAL '10 minutes';
    
    UPDATE public.user_presence
    SET status = 'offline'::public.presence_status
    WHERE last_seen < CURRENT_TIMESTAMP - INTERVAL '10 minutes'
    AND status != 'offline'::public.presence_status;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_sync_status(
    p_user_id UUID,
    p_document_id UUID,
    p_status public.sync_status
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.sync_status_log (user_id, document_id, status)
    VALUES (p_user_id, p_document_id, p_status);
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_viewers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_status_log ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- User Presence
DROP POLICY IF EXISTS "users_view_all_presence" ON public.user_presence;
CREATE POLICY "users_view_all_presence"
ON public.user_presence
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "users_manage_own_presence" ON public.user_presence;
CREATE POLICY "users_manage_own_presence"
ON public.user_presence
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Document Viewers
DROP POLICY IF EXISTS "users_view_document_viewers" ON public.document_viewers;
CREATE POLICY "users_view_document_viewers"
ON public.document_viewers
FOR SELECT
TO authenticated
USING (public.can_access_document(document_id));

DROP POLICY IF EXISTS "users_manage_own_viewing" ON public.document_viewers;
CREATE POLICY "users_manage_own_viewing"
ON public.document_viewers
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid() AND public.can_access_document(document_id));

-- Sync Status Log
DROP POLICY IF EXISTS "users_view_own_sync_status" ON public.sync_status_log;
CREATE POLICY "users_view_own_sync_status"
ON public.sync_status_log
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_create_sync_status" ON public.sync_status_log;
CREATE POLICY "users_create_sync_status"
ON public.sync_status_log
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());
