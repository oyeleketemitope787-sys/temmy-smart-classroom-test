-- TEST ONLY: secure game-result recording.
-- Review and apply manually in the TEST Supabase SQL Editor.
-- This file does not execute automatically.

CREATE OR REPLACE FUNCTION public.record_student_game_result(
    p_session_token uuid,
    p_game_id text,
    p_game_name text,
    p_score integer,
    p_max_score integer
)
RETURNS TABLE(
    points_awarded integer,
    score integer,
    max_score integer,
    action_name text,
    recorded_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_session record;
    v_teacher_id uuid;
    v_points integer;
    v_claimed_session_id uuid;
    v_recorded_at timestamp with time zone;
BEGIN
    -- Reject missing or invalid input, including scores above the maximum.
    IF p_session_token IS NULL
       OR p_game_id IS NULL
       OR trim(p_game_id) = ''
       OR p_game_name IS NULL
       OR trim(p_game_name) = ''
       OR p_score IS NULL
       OR p_max_score IS NULL
       OR p_score < 0
       OR p_max_score <= 0
       OR p_score > p_max_score
    THEN
        RETURN;
    END IF;

    -- Serialize attempts using the same session token.
    SELECT
        sgs.id,
        sgs.student_id,
        sgs.class_id,
        sgs.game_id,
        sgs.expires_at,
        sgs.used_at
    INTO v_session
    FROM public.student_game_sessions AS sgs
    WHERE sgs.session_token = p_session_token
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF v_session.used_at IS NOT NULL
       OR v_session.expires_at <= now()
    THEN
        RETURN;
    END IF;

    IF v_session.game_id IS DISTINCT FROM p_game_id THEN
        RETURN;
    END IF;

    SELECT c.teacher_id
    INTO v_teacher_id
    FROM public.classes AS c
    WHERE c.id = v_session.class_id
      AND c.active = true;

    IF v_teacher_id IS NULL THEN
        RETURN;
    END IF;

    -- Consume this session before inserting the points. Both changes run
    -- in the same transaction, so a failed insert rolls back the claim.
    UPDATE public.student_game_sessions
    SET used_at = now()
    WHERE id = v_session.id
      AND used_at IS NULL
      AND expires_at > now()
    RETURNING id, used_at
    INTO v_claimed_session_id, v_recorded_at;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Official score excludes arcade bonuses and is limited to the
    -- number of questions. Award exactly the validated score.
    v_points := p_score;

    INSERT INTO public.point_transactions (
        student_id,
        teacher_id,
        points,
        action_name,
        action_type,
        reason,
        source
    )
    VALUES (
        v_session.student_id,
        v_teacher_id,
        v_points,
        trim(p_game_name),
        'activity_score',
        'Game completed — ' || p_score || '/' || p_max_score,
        'game'
    );

    RETURN QUERY
    SELECT
        v_points,
        p_score,
        p_max_score,
        trim(p_game_name),
        v_recorded_at;
END;
$function$;
