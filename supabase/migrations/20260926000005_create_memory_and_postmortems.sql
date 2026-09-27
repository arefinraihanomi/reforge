-- ==============================================================================
-- Migration: 20260926000005_create_memory_and_postmortems.sql
-- Description: Create project_decisions, project_postmortems, and project_lessons tables with RLS constraints.
-- ==============================================================================

-- 1. Create project_decisions (Project Memory)
CREATE TABLE IF NOT EXISTS public.project_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0),
    decision TEXT NOT NULL,
    rationale TEXT,
    entry_type TEXT NOT NULL DEFAULT 'decision' CHECK (entry_type IN ('decision', 'blocker', 'note')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Create project_postmortems
CREATE TABLE IF NOT EXISTS public.project_postmortems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID UNIQUE NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    primary_reason TEXT NOT NULL CHECK (primary_reason IN ('scope_creep', 'technical_blocker', 'shifted_interest', 'time_constraint', 'other')),
    what_went_wrong TEXT NOT NULL,
    what_went_well TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Create project_lessons (Reusable Knowledge Bank)
CREATE TABLE IF NOT EXISTS public.project_lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    postmortem_id UUID REFERENCES public.project_postmortems(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lesson TEXT NOT NULL CHECK (char_length(trim(lesson)) > 0),
    category TEXT NOT NULL DEFAULT 'architecture' CHECK (category IN ('architecture', 'scope', 'technical', 'process', 'other')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_project_decisions_project ON public.project_decisions (project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_project_decisions_user_type ON public.project_decisions (user_id, entry_type);

CREATE INDEX IF NOT EXISTS idx_project_postmortems_user ON public.project_postmortems (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_project_lessons_user_cat ON public.project_lessons (user_id, category);
CREATE INDEX IF NOT EXISTS idx_project_lessons_project ON public.project_lessons (project_id);

-- 5. Enable Row-Level Security (RLS)
ALTER TABLE public.project_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_postmortems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_lessons ENABLE ROW LEVEL SECURITY;

-- 6. Row-Level Security Policies

-- project_decisions RLS
CREATE POLICY "Users can view their own project decisions"
    ON public.project_decisions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own project decisions"
    ON public.project_decisions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own project decisions"
    ON public.project_decisions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own project decisions"
    ON public.project_decisions
    FOR DELETE
    USING (auth.uid() = user_id);

-- project_postmortems RLS
CREATE POLICY "Users can view their own project postmortems"
    ON public.project_postmortems
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own project postmortems"
    ON public.project_postmortems
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own project postmortems"
    ON public.project_postmortems
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own project postmortems"
    ON public.project_postmortems
    FOR DELETE
    USING (auth.uid() = user_id);

-- project_lessons RLS
CREATE POLICY "Users can view their own project lessons"
    ON public.project_lessons
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own project lessons"
    ON public.project_lessons
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own project lessons"
    ON public.project_lessons
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own project lessons"
    ON public.project_lessons
    FOR DELETE
    USING (auth.uid() = user_id);

-- 7. Trigger for updated_at
DROP TRIGGER IF EXISTS set_project_postmortems_updated_at ON public.project_postmortems;
CREATE TRIGGER set_project_postmortems_updated_at
    BEFORE UPDATE ON public.project_postmortems
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
