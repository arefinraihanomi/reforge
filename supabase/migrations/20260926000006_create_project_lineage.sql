-- ==============================================================================
-- Migration: 20260926000006_create_project_lineage.sql
-- Description: Create project_versions table to model V1 -> V2 project resurrection lineage.
-- ==============================================================================

-- 1. Create project_versions table
CREATE TABLE IF NOT EXISTS public.project_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    source_project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    new_project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    version_label TEXT NOT NULL DEFAULT 'v2' CHECK (char_length(trim(version_label)) > 0),
    changes_summary TEXT,
    lessons_applied JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_no_self_referential_lineage CHECK (source_project_id != new_project_id)
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_project_versions_user ON public.project_versions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_project_versions_source ON public.project_versions (source_project_id);
CREATE INDEX IF NOT EXISTS idx_project_versions_new ON public.project_versions (new_project_id);

-- 3. Enable Row-Level Security (RLS)
ALTER TABLE public.project_versions ENABLE ROW LEVEL SECURITY;

-- 4. Row-Level Security Policies
CREATE POLICY "Users can view their own project versions"
    ON public.project_versions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own project versions"
    ON public.project_versions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own project versions"
    ON public.project_versions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own project versions"
    ON public.project_versions
    FOR DELETE
    USING (auth.uid() = user_id);
