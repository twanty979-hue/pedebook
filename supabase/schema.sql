-- ==============================================================================
-- PEDEBOOK - SUPABASE DATABASE SCHEMA
-- Version: 2.0 (PostgreSQL / Supabase)
-- Description: Complete schema supporting Multi-Tenant SaaS, Team Collaboration
--              (Up to 10 members for Business Plan), Per-Page Analytics Tracking,
--              Tiered Pricing Plans, and Unblockable Ads for Over-Quota Free Users.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
DO $$ BEGIN
    CREATE TYPE plan_tier AS ENUM ('free', 'pro', 'ultra', 'business');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE team_role AS ENUM ('owner', 'admin', 'editor', 'viewer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE team_member_status AS ENUM ('pending', 'accepted', 'declined');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ad_type AS ENUM ('countdown_overlay', 'sticky_banner', 'interstitial');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 3. TABLES
-- ==============================================================================

-- 3.1 PROFILES (Linked directly to Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    current_plan plan_tier NOT NULL DEFAULT 'free',
    storage_used_bytes BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Index for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_plan ON public.profiles(current_plan);

-- 3.2 TEAMS (For Business Plan - Supports inviting up to 10 members)
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan plan_tier NOT NULL DEFAULT 'business',
    max_members INT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE INDEX IF NOT EXISTS idx_teams_owner ON public.teams(owner_id);

-- 3.3 TEAM MEMBERS (Role-based access, strict maximum 10 members check)
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    invited_email TEXT NOT NULL,
    role team_role NOT NULL DEFAULT 'editor',
    status team_member_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    CONSTRAINT unique_team_member_user UNIQUE(team_id, user_id),
    CONSTRAINT unique_team_member_email UNIQUE(team_id, invited_email)
);

CREATE INDEX IF NOT EXISTS idx_team_members_team ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON public.team_members(user_id);

-- 3.4 CATALOGS (Flipbook definitions & metadata)
CREATE TABLE IF NOT EXISTS public.catalogs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    file_name TEXT NOT NULL,
    pdf_url TEXT NOT NULL,
    storage_key TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL DEFAULT 0,
    page_count INT NOT NULL DEFAULT 0,
    bg_type TEXT NOT NULL DEFAULT 'gradient',
    bg_value TEXT NOT NULL DEFAULT 'auto',
    is_floating BOOLEAN NOT NULL DEFAULT FALSE,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    allow_indexing BOOLEAN NOT NULL DEFAULT FALSE,
    seo_description TEXT,
    -- If true, readers of this catalog will see unblockable ads (for Free users exceeding 100MB)
    ad_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    total_views BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE INDEX IF NOT EXISTS idx_catalogs_user ON public.catalogs(user_id);
CREATE INDEX IF NOT EXISTS idx_catalogs_team ON public.catalogs(team_id);
CREATE INDEX IF NOT EXISTS idx_catalogs_slug ON public.catalogs(slug);
CREATE INDEX IF NOT EXISTS idx_catalogs_created ON public.catalogs(created_at DESC);

-- 3.5 CATALOG PAGE STATS (Aggregated page-by-page metrics for creator dashboard)
CREATE TABLE IF NOT EXISTS public.catalog_page_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_id UUID NOT NULL REFERENCES public.catalogs(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    view_count BIGINT NOT NULL DEFAULT 0,
    total_duration_seconds NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    avg_duration_seconds NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW()),
    CONSTRAINT unique_catalog_page_stats UNIQUE(catalog_id, page_number)
);

CREATE INDEX IF NOT EXISTS idx_page_stats_catalog ON public.catalog_page_stats(catalog_id);
CREATE INDEX IF NOT EXISTS idx_page_stats_page ON public.catalog_page_stats(catalog_id, page_number);

-- 3.6 PAGE ANALYTICS LOGS (Individual raw session pings for heatmaps and deep dive)
CREATE TABLE IF NOT EXISTS public.page_analytics_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_id UUID NOT NULL REFERENCES public.catalogs(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    session_id TEXT NOT NULL,
    duration_seconds NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    device_type TEXT NOT NULL DEFAULT 'desktop', -- 'mobile', 'tablet', 'desktop'
    user_agent TEXT,
    referrer TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE INDEX IF NOT EXISTS idx_analytics_catalog_time ON public.page_analytics_logs(catalog_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_session ON public.page_analytics_logs(session_id);

-- 3.7 AD CAMPAIGNS (Injected unblockable ads for over-quota free books)
CREATE TABLE IF NOT EXISTS public.ad_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    sponsor_name TEXT NOT NULL,
    banner_image_url TEXT NOT NULL,
    target_url TEXT NOT NULL,
    ad_type ad_type NOT NULL DEFAULT 'countdown_overlay',
    duration_seconds INT NOT NULL DEFAULT 5,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    impressions BIGINT NOT NULL DEFAULT 0,
    clicks BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ==============================================================================
-- 4. DATABASE FUNCTIONS & TRIGGERS
-- ==============================================================================

-- 4.1 Trigger to automatically create a profile when auth.users signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, avatar_url, current_plan)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
        'free'
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4.2 Enforce maximum 10 members per team (Business Plan constraint)
CREATE OR REPLACE FUNCTION public.enforce_team_member_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_member_count INT;
    team_max_limit INT;
BEGIN
    SELECT COUNT(*) INTO current_member_count
    FROM public.team_members
    WHERE team_id = NEW.team_id;

    SELECT max_members INTO team_max_limit
    FROM public.teams
    WHERE id = NEW.team_id;

    IF current_member_count >= COALESCE(team_max_limit, 10) THEN
        RAISE EXCEPTION 'จำนวนสมาชิกในทีมครบขีดจำกัด % คนแล้วครับ (แพ็กเกจ Business รองรับสูงสุด 10 คนต่อทีม)', COALESCE(team_max_limit, 10);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_team_member_limit ON public.team_members;
CREATE TRIGGER trigger_team_member_limit
    BEFORE INSERT ON public.team_members
    FOR EACH ROW EXECUTE FUNCTION public.enforce_team_member_limit();

-- 4.3 Stored Procedure to record page stay time atomically and update aggregates
CREATE OR REPLACE FUNCTION public.record_page_stay_time(
    p_catalog_id TEXT,
    p_page_number INT,
    p_duration_seconds NUMERIC,
    p_session_id TEXT,
    p_device_type TEXT DEFAULT 'desktop',
    p_user_agent TEXT DEFAULT NULL,
    p_referrer TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_catalog_uuid UUID;
BEGIN
    -- Check if p_catalog_id is already a valid UUID
    IF p_catalog_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
        v_catalog_uuid := p_catalog_id::UUID;
    ELSE
        -- Lookup by slug
        SELECT id INTO v_catalog_uuid FROM public.catalogs WHERE slug = p_catalog_id LIMIT 1;
    END IF;

    -- If still null, return
    IF v_catalog_uuid IS NULL THEN
        RETURN;
    END IF;

    -- 1. Insert into raw event log (fixed column order!)
    INSERT INTO public.page_analytics_logs (
        catalog_id,
        page_number,
        session_id,
        duration_seconds,
        device_type,
        user_agent,
        referrer
    ) VALUES (
        v_catalog_uuid,
        p_page_number,
        p_session_id,
        LEAST(p_duration_seconds, 600.00),
        p_device_type,
        p_user_agent,
        p_referrer
    );

    -- 2. Upsert aggregated stats for fast dashboard charts
    INSERT INTO public.catalog_page_stats (
        catalog_id,
        page_number,
        view_count,
        total_duration_seconds,
        avg_duration_seconds,
        updated_at
    ) VALUES (
        v_catalog_uuid,
        p_page_number,
        1,
        LEAST(p_duration_seconds, 600.00),
        LEAST(p_duration_seconds, 600.00),
        NOW()
    )
    ON CONFLICT (catalog_id, page_number) DO UPDATE
    SET view_count = public.catalog_page_stats.view_count + 1,
        total_duration_seconds = public.catalog_page_stats.total_duration_seconds + LEAST(EXCLUDED.total_duration_seconds, 600.00),
        avg_duration_seconds = ROUND(
            (public.catalog_page_stats.total_duration_seconds + LEAST(EXCLUDED.total_duration_seconds, 600.00)) /
            (public.catalog_page_stats.view_count + 1),
            2
        ),
        updated_at = NOW();

    -- 3. Increment overall catalog view count if first page
    IF p_page_number = 1 THEN
        UPDATE public.catalogs
        SET total_views = total_views + 1,
            updated_at = NOW()
        WHERE id = v_catalog_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.4 Trigger to recalculate storage usage and check 100MB Free Tier Ad quota
CREATE OR REPLACE FUNCTION public.recalculate_user_storage_and_ads()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    total_size BIGINT;
    user_plan plan_tier;
BEGIN
    target_user_id := COALESCE(NEW.user_id, OLD.user_id);

    -- Calculate total size of catalogs owned by this user
    SELECT COALESCE(SUM(file_size_bytes), 0) INTO total_size
    FROM public.catalogs
    WHERE user_id = target_user_id;

    -- Fetch current plan
    SELECT current_plan INTO user_plan
    FROM public.profiles
    WHERE id = target_user_id;

    -- Update storage_used_bytes in profile
    UPDATE public.profiles
    SET storage_used_bytes = total_size,
        updated_at = NOW()
    WHERE id = target_user_id;

    -- Over-quota Rule: Free plan limit is 100MB (104,857,600 bytes)
    -- If free user exceeds 100MB, ad_enabled = TRUE on all their catalogs.
    -- If they upgrade to Pro/Ultra/Business, ad_enabled = FALSE immediately.
    IF user_plan = 'free' AND total_size > 104857600 THEN
        UPDATE public.catalogs
        SET ad_enabled = TRUE
        WHERE user_id = target_user_id;
    ELSE
        UPDATE public.catalogs
        SET ad_enabled = FALSE
        WHERE user_id = target_user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_catalog_storage_calc ON public.catalogs;
CREATE TRIGGER trigger_catalog_storage_calc
    AFTER INSERT OR UPDATE OF file_size_bytes OR DELETE ON public.catalogs
    FOR EACH ROW EXECUTE FUNCTION public.recalculate_user_storage_and_ads();

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalog_page_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_analytics_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;

-- 5.1 Profiles: Users can view and update their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 5.2 Catalogs: Public can view public catalogs; owners & team members can manage
CREATE POLICY "Public catalogs are viewable by anyone"
    ON public.catalogs FOR SELECT
    USING (is_public = TRUE OR auth.uid() = user_id);

CREATE POLICY "Users can insert their own catalogs"
    ON public.catalogs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own or team catalogs"
    ON public.catalogs FOR UPDATE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.team_members
            WHERE team_id = catalogs.team_id
              AND user_id = auth.uid()
              AND role IN ('owner', 'admin', 'editor')
        )
    );

CREATE POLICY "Users can delete own or team catalogs"
    ON public.catalogs FOR DELETE
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.team_members
            WHERE team_id = catalogs.team_id
              AND user_id = auth.uid()
              AND role IN ('owner', 'admin')
        )
    );

-- 5.3 Teams: Owners & members can view their teams
CREATE POLICY "Team members can view team"
    ON public.teams FOR SELECT
    USING (
        auth.uid() = owner_id OR
        EXISTS (
            SELECT 1 FROM public.team_members
            WHERE team_id = teams.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Owners can manage teams"
    ON public.teams FOR ALL
    USING (auth.uid() = owner_id);

-- 5.4 Team Members:
CREATE POLICY "View team members"
    ON public.team_members FOR SELECT
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.teams
            WHERE id = team_members.team_id AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Owners can manage members"
    ON public.team_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.teams
            WHERE id = team_members.team_id AND owner_id = auth.uid()
        )
    );

-- 5.5 Analytics: Catalog owners can read page stats
CREATE POLICY "Owners can view page stats"
    ON public.catalog_page_stats FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.catalogs
            WHERE id = catalog_page_stats.catalog_id AND user_id = auth.uid()
        )
    );

-- 5.6 Ad campaigns: Active ads are viewable by anyone
CREATE POLICY "Anyone can view active ads"
    ON public.ad_campaigns FOR SELECT
    USING (is_active = TRUE);

-- ==============================================================================
-- 6. DEFAULT SEED DATA
-- ==============================================================================
INSERT INTO public.ad_campaigns (title, sponsor_name, banner_image_url, target_url, ad_type, duration_seconds, is_active)
VALUES (
    'สร้างแค็ตตาล็อกออนไลน์ 3D Flipbook ฟรี',
    'Pedebook Official',
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=1200&q=80',
    'https://www.pedebook.com',
    'countdown_overlay',
    5,
    TRUE
) ON CONFLICT DO NOTHING;
