-- Collaborative Document Annotations Migration
-- Enables real-time collaborative document annotations and sharing between team members

-- 1. Types
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('admin', 'member');

DROP TYPE IF EXISTS public.annotation_type CASCADE;
CREATE TYPE public.annotation_type AS ENUM ('highlight', 'note', 'drawing', 'text', 'shape');

DROP TYPE IF EXISTS public.share_permission CASCADE;
CREATE TYPE public.share_permission AS ENUM ('view', 'comment', 'edit');

-- 2. Core Tables
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    role public.user_role DEFAULT 'member'::public.user_role,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    size TEXT,
    thumbnail_url TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    is_favorite BOOLEAN DEFAULT false,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    annotation_type public.annotation_type NOT NULL,
    page_number INTEGER NOT NULL,
    color TEXT,
    thickness REAL,
    content TEXT,
    position_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_with_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    permission public.share_permission DEFAULT 'view'::public.share_permission,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(document_id, shared_with_user_id)
);

CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role public.user_role DEFAULT 'member'::public.user_role,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.team_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id, document_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_documents_owner_id ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON public.documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_annotations_document_id ON public.annotations(document_id);
CREATE INDEX IF NOT EXISTS idx_annotations_user_id ON public.annotations(user_id);
CREATE INDEX IF NOT EXISTS idx_annotations_created_at ON public.annotations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_document_shares_document_id ON public.document_shares(document_id);
CREATE INDEX IF NOT EXISTS idx_document_shares_shared_with ON public.document_shares(shared_with_user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_documents_team_id ON public.team_documents(team_id);
CREATE INDEX IF NOT EXISTS idx_team_documents_document_id ON public.team_documents(document_id);

-- 4. Functions (BEFORE RLS policies)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'member'::public.user_role)
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.can_access_document(doc_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = doc_id AND d.owner_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.document_shares ds
        WHERE ds.document_id = doc_id AND ds.shared_with_user_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.team_documents td
        JOIN public.team_members tm ON td.team_id = tm.team_id
        WHERE td.document_id = doc_id AND tm.user_id = auth.uid()
    );
$$;

CREATE OR REPLACE FUNCTION public.can_edit_document(doc_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = doc_id AND d.owner_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.document_shares ds
        WHERE ds.document_id = doc_id 
        AND ds.shared_with_user_id = auth.uid() 
        AND ds.permission = 'edit'::public.share_permission
    );
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_documents ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- User Profiles
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "users_view_other_profiles" ON public.user_profiles;
CREATE POLICY "users_view_other_profiles"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (true);

-- Documents
DROP POLICY IF EXISTS "users_manage_own_documents" ON public.documents;
CREATE POLICY "users_manage_own_documents"
ON public.documents
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "users_view_shared_documents" ON public.documents;
CREATE POLICY "users_view_shared_documents"
ON public.documents
FOR SELECT
TO authenticated
USING (public.can_access_document(id));

-- Annotations
DROP POLICY IF EXISTS "users_manage_own_annotations" ON public.annotations;
CREATE POLICY "users_manage_own_annotations"
ON public.annotations
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid() AND public.can_edit_document(document_id));

DROP POLICY IF EXISTS "users_view_document_annotations" ON public.annotations;
CREATE POLICY "users_view_document_annotations"
ON public.annotations
FOR SELECT
TO authenticated
USING (public.can_access_document(document_id));

-- Document Shares
DROP POLICY IF EXISTS "owners_manage_document_shares" ON public.document_shares;
CREATE POLICY "owners_manage_document_shares"
ON public.document_shares
FOR ALL
TO authenticated
USING (
    shared_by_user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.documents d WHERE d.id = document_id AND d.owner_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.documents d WHERE d.id = document_id AND d.owner_id = auth.uid())
);

DROP POLICY IF EXISTS "users_view_own_shares" ON public.document_shares;
CREATE POLICY "users_view_own_shares"
ON public.document_shares
FOR SELECT
TO authenticated
USING (shared_with_user_id = auth.uid());

-- Teams
DROP POLICY IF EXISTS "users_manage_own_teams" ON public.teams;
CREATE POLICY "users_manage_own_teams"
ON public.teams
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "members_view_teams" ON public.teams;
CREATE POLICY "members_view_teams"
ON public.teams
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm
        WHERE tm.team_id = id AND tm.user_id = auth.uid()
    )
);

-- Team Members
DROP POLICY IF EXISTS "owners_manage_team_members" ON public.team_members;
CREATE POLICY "owners_manage_team_members"
ON public.team_members
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.teams t
        WHERE t.id = team_id AND t.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.teams t
        WHERE t.id = team_id AND t.owner_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "members_view_team_members" ON public.team_members;
CREATE POLICY "members_view_team_members"
ON public.team_members
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

-- Team Documents
DROP POLICY IF EXISTS "owners_manage_team_documents" ON public.team_documents;
CREATE POLICY "owners_manage_team_documents"
ON public.team_documents
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.teams t
        WHERE t.id = team_id AND t.owner_id = auth.uid()
    ) OR
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = document_id AND d.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.teams t
        WHERE t.id = team_id AND t.owner_id = auth.uid()
    ) OR
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = document_id AND d.owner_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "members_view_team_documents" ON public.team_documents;
CREATE POLICY "members_view_team_documents"
ON public.team_documents
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

-- 7. Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_documents_updated_at ON public.documents;
CREATE TRIGGER update_documents_updated_at
BEFORE UPDATE ON public.documents
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_annotations_updated_at ON public.annotations;
CREATE TRIGGER update_annotations_updated_at
BEFORE UPDATE ON public.annotations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_teams_updated_at ON public.teams;
CREATE TRIGGER update_teams_updated_at
BEFORE UPDATE ON public.teams
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 8. Mock Data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    user1_uuid UUID := gen_random_uuid();
    user2_uuid UUID := gen_random_uuid();
    doc1_uuid UUID := gen_random_uuid();
    doc2_uuid UUID := gen_random_uuid();
    team_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users (trigger creates user_profiles automatically)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@easypdf.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Admin User', 'role', 'admin'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'marie.dupont@easypdf.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Marie Dupont'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'jean.martin@easypdf.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Jean Martin'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

    -- Create documents
    INSERT INTO public.documents (id, owner_id, name, size, thumbnail_url, is_favorite, tags)
    VALUES
        (doc1_uuid, admin_uuid, 'Rapport_Annuel_2025.pdf', '2.4 MB',
         'https://img.rocket.new/generatedImages/rocket_gen_img_1712339cd-1765570178329.png',
         true, ARRAY['Rapport', '2025']::TEXT[]),
        (doc2_uuid, admin_uuid, 'Contrat_Client_Dupont.pdf', '1.8 MB',
         'https://img.rocket.new/generatedImages/rocket_gen_img_1504053bf-1764783239720.png',
         false, ARRAY['Contrat', 'Client']::TEXT[])
    ON CONFLICT (id) DO NOTHING;

    -- Create team
    INSERT INTO public.teams (id, name, owner_id)
    VALUES (team_uuid, 'Marketing Team', admin_uuid)
    ON CONFLICT (id) DO NOTHING;

    -- Add team members
    INSERT INTO public.team_members (team_id, user_id, role)
    VALUES
        (team_uuid, user1_uuid, 'member'::public.user_role),
        (team_uuid, user2_uuid, 'member'::public.user_role)
    ON CONFLICT (team_id, user_id) DO NOTHING;

    -- Share document with team
    INSERT INTO public.team_documents (team_id, document_id, shared_by_user_id)
    VALUES (team_uuid, doc1_uuid, admin_uuid)
    ON CONFLICT (team_id, document_id) DO NOTHING;

    -- Share document directly with user
    INSERT INTO public.document_shares (document_id, shared_with_user_id, shared_by_user_id, permission)
    VALUES (doc2_uuid, user1_uuid, admin_uuid, 'edit'::public.share_permission)
    ON CONFLICT (document_id, shared_with_user_id) DO NOTHING;

    -- Create sample annotations
    INSERT INTO public.annotations (document_id, user_id, annotation_type, page_number, color, content)
    VALUES
        (doc1_uuid, admin_uuid, 'highlight'::public.annotation_type, 3, '#FFEB3B', 'Key financial metrics'),
        (doc1_uuid, user1_uuid, 'note'::public.annotation_type, 5, '#E57373', 'Review with team before presentation'),
        (doc2_uuid, admin_uuid, 'text'::public.annotation_type, 2, '#000000', 'Update contract terms')
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;