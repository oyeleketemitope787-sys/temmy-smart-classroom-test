-- TEST ONLY — Grade 3 Temmy Number Challenge result recording hardening.
-- REVIEW FILE ONLY. DO NOT EXECUTE THIS MIGRATION YET.
-- Execute only after a separate, isolated TEST Supabase project is created,
-- its schema is verified, and the project/branch identity is confirmed.
-- NEVER run this against project ref askhdgmjqezvwavfhqzj or any branch labelled PRODUCTION.
--
-- This is intentionally scoped to one known game:
--   game_id: grade3-temmy-number-challenge
--   official question count: 15
--   official game name: Temmy Number Challenge
-- The caller-supplied max/name are checked against these server-side constants.
-- Arcade bonus points are never submitted as official points.
--
-- Assumptions to verify before use:
-- 1. public.student_game_sessions has id, student_id, class_id, game_id,
--    session_token, expires_at, and used_at.
-- 2. public.students has id, class_id, and active.
-- 3. public.classes has id, teacher_id, and active.
-- 4. public.point_transactions accepts action_type='activity_score' and source='game'.
-- 5. The function owner can safely write to the required tables.
-- 6. The browser submits with the Supabase anon role; the session token is a
--    bearer secret and must not be logged or exposed to third parties.

BEGIN;

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
    c_game_id CONSTANT text := 'grade3-temmy-number-challenge';
    c_game_name CONSTANT text := 'Temmy Number Challenge';
    c_max_score CONSTANT integer := 15;
    v_session record;
    v_teacher_id uuid;
    v_claimed_session_id uuid;
    v_recorded_at timestamptz;
BEGIN
    -- Validate all caller-controlled values against server-owned constants.
    IF p_session_token IS NULL
       OR p_game_id IS DISTINCT FROM c_game_id
       OR p_game_name IS DISTINCT FROM c_game_name
       OR p_score IS NULL
       OR p_max_score IS DISTINCT FROM c_max_score
       OR p_score < 0
       OR p_score > c_max_score
    THEN
        RETURN;
    END IF;

    -- Lock the session so concurrent submissions serialize on this row.
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

    IF NOT FOUND
       OR v_session.used_at IS NOT NULL
       OR v_session.expires_at <= now()
       OR v_session.game_id IS DISTINCT FROM c_game_id
    THEN
        RETURN;
    END IF;

    -- Revalidate that the student and class remain active and related.
    SELECT c.teacher_id
    INTO v_teacher_id
    FROM public.classes AS c
    JOIN public.students AS s
      ON s.class_id = c.id
    WHERE c.id = v_session.class_id
      AND s.id = v_session.student_id
      AND c.active = true
      AND s.active = true;

    IF NOT FOUND OR v_teacher_id IS NULL THEN
        RETURN;
    END IF;

    -- Claim the session before awarding points. Row lock plus conditional
    -- update ensures only one transaction can consume this session.
    UPDATE public.student_game_sessions AS sgs
    SET used_at = now()
    WHERE sgs.id = v_session.id
      AND sgs.used_at IS NULL
      AND sgs.expires_at > now()
      AND sgs.game_id = c_game_id
    RETURNING sgs.id, sgs.used_at
    INTO v_claimed_session_id, v_recorded_at;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- The official score is the number correct, not arcade points/bonuses.
    -- If this insert fails, the transaction rolls back the used_at claim too.
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
        p_score,
        c_game_name,
        'activity_score',
        'Game completed — ' || p_score || '/' || c_max_score,
        'game'
    );

    RETURN QUERY
    SELECT
        p_score,
        p_score,
        c_max_score,
        c_game_name,
        v_recorded_at;
END;
$function$;

-- The browser calls this RPC using the anon role when a valid session token
-- is present. All arguments are validated above; no other roles need access.
REVOKE ALL ON FUNCTION public.record_student_game_result(uuid, text, text, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_student_game_result(uuid, text, text, integer, integer) FROM anon;
REVOKE ALL ON FUNCTION public.record_student_game_result(uuid, text, text, integer, integer) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.record_student_game_result(uuid, text, text, integer, integer) TO anon, authenticated;

COMMIT;
