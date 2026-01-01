-- Create a view to efficiently query exercise history
-- Shows the last sessions for each exercise with set details
CREATE OR REPLACE VIEW exercise_history AS
SELECT
    ep.exercise_id,
    ep.id as exercise_performance_id,
    ws.user_id,
    ws.id as workout_session_id,
    ws.title as workout_title,
    ws.completed_at,
    s.id as set_id,
    s.set_number,
    s.reps,
    s.weight_kg,
    s.is_warmup,
    s.rpe,
    ROW_NUMBER() OVER (
        PARTITION BY ep.exercise_id, ws.user_id
        ORDER BY ws.completed_at DESC, s.set_number ASC
    ) as row_num
FROM exercise_performances ep
INNER JOIN workout_sessions ws ON ep.workout_session_id = ws.id
INNER JOIN sets s ON s.exercise_performance_id = ep.id
WHERE ws.completed_at IS NOT NULL  -- Only completed workouts
ORDER BY ws.completed_at DESC, s.set_number ASC;

-- Create function to get exercise history for a specific exercise and user
-- Returns the last N workout sessions with all their sets
CREATE OR REPLACE FUNCTION get_exercise_history(
    p_user_id UUID,
    p_exercise_id UUID,
    p_limit INTEGER DEFAULT 3
)
RETURNS TABLE (
    workout_session_id UUID,
    workout_title TEXT,
    completed_at TIMESTAMPTZ,
    set_number INTEGER,
    reps INTEGER,
    weight_kg DECIMAL(6,2),
    is_warmup BOOLEAN,
    rpe DECIMAL(3,1)
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        eh.workout_session_id,
        eh.workout_title,
        eh.completed_at,
        eh.set_number,
        eh.reps,
        eh.weight_kg,
        eh.is_warmup,
        eh.rpe
    FROM exercise_history eh
    WHERE eh.user_id = p_user_id
      AND eh.exercise_id = p_exercise_id
      AND eh.workout_session_id IN (
          -- Get the last N distinct workout sessions for this exercise
          SELECT DISTINCT workout_session_id
          FROM exercise_history
          WHERE user_id = p_user_id AND exercise_id = p_exercise_id
          ORDER BY completed_at DESC
          LIMIT p_limit
      )
    ORDER BY eh.completed_at DESC, eh.set_number ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add RLS policy for the function
-- Users can only see their own exercise history
ALTER FUNCTION get_exercise_history(UUID, UUID, INTEGER) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION get_exercise_history(UUID, UUID, INTEGER) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_exercise_history IS 'Returns the last N workout sessions for a specific exercise and user, with all sets included';
