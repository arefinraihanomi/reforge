-- ==============================================================================
-- Migration: 20260926000004_convert_idea_rpc.sql
-- Description: PL/pgSQL RPC function to convert an idea into an active project atomically.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.convert_idea_to_project(
    p_idea_id UUID,
    p_mvp_scope TEXT DEFAULT NULL,
    p_initial_tasks JSONB DEFAULT '[]'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_idea_record RECORD;
    v_new_project_id UUID;
    v_task_elem JSONB;
    v_task_title TEXT;
    v_pos INT := 0;
BEGIN
    -- 1. Get current authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = '42501';
    END IF;

    -- 2. Fetch and lock the target idea owned by user
    SELECT * INTO v_idea_record
    FROM public.ideas
    WHERE id = p_idea_id AND user_id = v_user_id;

    IF v_idea_record.id IS NULL THEN
        RAISE EXCEPTION 'Idea not found or unauthorized.' USING ERRCODE = 'P0002';
    END IF;

    -- 3. Create new project record
    INSERT INTO public.projects (
        user_id,
        idea_id,
        title,
        summary,
        mvp_scope,
        status
    ) VALUES (
        v_user_id,
        v_idea_record.id,
        v_idea_record.title,
        COALESCE(v_idea_record.description, v_idea_record.problem),
        COALESCE(p_mvp_scope, v_idea_record.hypothesis),
        'active'
    )
    RETURNING id INTO v_new_project_id;

    -- 4. Mark original idea as converted
    UPDATE public.ideas
    SET status = 'converted',
        stage = 'building',
        updated_at = timezone('utc'::text, now())
    WHERE id = v_idea_record.id;

    -- 5. Seed initial project tasks if provided in JSONB array
    IF jsonb_typeof(p_initial_tasks) = 'array' THEN
        FOR v_task_elem IN SELECT * FROM jsonb_array_elements(p_initial_tasks)
        LOOP
            IF jsonb_typeof(v_task_elem) = 'string' THEN
                v_task_title := trim(both '"' from v_task_elem::text);
            ELSIF jsonb_typeof(v_task_elem) = 'object' AND v_task_elem ? 'title' THEN
                v_task_title := v_task_elem->>'title';
            ELSE
                v_task_title := NULL;
            END IF;

            IF v_task_title IS NOT NULL AND char_length(trim(v_task_title)) > 0 THEN
                INSERT INTO public.project_tasks (
                    project_id,
                    user_id,
                    title,
                    status,
                    position
                ) VALUES (
                    v_new_project_id,
                    v_user_id,
                    trim(v_task_title),
                    'pending',
                    v_pos
                );
                v_pos := v_pos + 1;
            END IF;
        END LOOP;
    END IF;

    RETURN v_new_project_id;
END;
$$;
