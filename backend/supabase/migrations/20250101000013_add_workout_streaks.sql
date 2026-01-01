-- Migration: Add Workout Streak Tracking
-- Description: Add streak fields to profiles table and create functions to calculate streaks
-- Date: 2025-01-01

-- Add streak tracking columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_workout_date DATE;

-- Create function to calculate workout streak for a user
-- A streak continues if the user works out on consecutive days (no gaps > 1 day)
CREATE OR REPLACE FUNCTION calculate_workout_streak(p_user_id UUID)
RETURNS TABLE(
  current_streak INTEGER,
  longest_streak INTEGER,
  last_workout_date DATE
) AS $$
DECLARE
  v_current_streak INTEGER := 0;
  v_longest_streak INTEGER := 0;
  v_last_date DATE;
  v_prev_date DATE;
  v_temp_streak INTEGER := 0;
  workout_rec RECORD;
BEGIN
  -- Get all distinct workout dates in descending order
  FOR workout_rec IN
    SELECT DISTINCT DATE(completed_at) AS workout_date
    FROM workout_sessions
    WHERE user_id = p_user_id
      AND completed_at IS NOT NULL
    ORDER BY workout_date DESC
  LOOP
    -- First iteration
    IF v_last_date IS NULL THEN
      v_last_date := workout_rec.workout_date;
      v_temp_streak := 1;
      v_current_streak := 1;
      v_longest_streak := 1;
    ELSE
      -- Check if this date is consecutive (1 day before previous)
      IF workout_rec.workout_date = v_prev_date - INTERVAL '1 day' THEN
        v_temp_streak := v_temp_streak + 1;

        -- Update current streak only if we're still in the recent consecutive range
        IF v_current_streak > 0 THEN
          v_current_streak := v_temp_streak;
        END IF;

        -- Update longest streak if needed
        IF v_temp_streak > v_longest_streak THEN
          v_longest_streak := v_temp_streak;
        END IF;
      ELSE
        -- Streak broken
        -- If gap is more than 1 day from today, current streak is 0
        IF v_prev_date < CURRENT_DATE - INTERVAL '1 day' THEN
          v_current_streak := 0;
        END IF;

        -- Reset temp streak
        v_temp_streak := 1;

        -- Update longest if previous streak was longer
        IF v_temp_streak > v_longest_streak THEN
          v_longest_streak := v_temp_streak;
        END IF;
      END IF;
    END IF;

    v_prev_date := workout_rec.workout_date;
  END LOOP;

  -- Check if current streak is still valid (workout within last day)
  IF v_last_date IS NOT NULL AND v_last_date < CURRENT_DATE - INTERVAL '1 day' THEN
    v_current_streak := 0;
  END IF;

  -- Return the calculated values
  RETURN QUERY SELECT v_current_streak, v_longest_streak, v_last_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update user's streak in profiles table
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  streak_data RECORD;
BEGIN
  -- Calculate the streak
  SELECT * INTO streak_data
  FROM calculate_workout_streak(p_user_id);

  -- Update the profiles table
  UPDATE profiles
  SET
    current_streak = streak_data.current_streak,
    longest_streak = streak_data.longest_streak,
    last_workout_date = streak_data.last_workout_date,
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically update streak when workout is completed
CREATE OR REPLACE FUNCTION trigger_update_streak()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update streak when a workout is completed (completed_at changes from NULL to a value)
  IF NEW.completed_at IS NOT NULL AND (OLD.completed_at IS NULL OR OLD.completed_at != NEW.completed_at) THEN
    PERFORM update_user_streak(NEW.user_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to workout_sessions table
DROP TRIGGER IF EXISTS update_streak_on_workout_complete ON workout_sessions;
CREATE TRIGGER update_streak_on_workout_complete
  AFTER UPDATE ON workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_streak();

-- Create index for efficient streak calculations
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_completed_date
ON workout_sessions(user_id, DATE(completed_at))
WHERE completed_at IS NOT NULL;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_workout_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_streak(UUID) TO authenticated;

-- Add RLS policy for streak data (users can only see their own streaks)
-- Note: Profiles table already has RLS policies from earlier migrations

-- Comments
COMMENT ON COLUMN profiles.current_streak IS
'Number of consecutive days the user has worked out (0 if broken)';

COMMENT ON COLUMN profiles.longest_streak IS
'Longest streak the user has ever achieved';

COMMENT ON COLUMN profiles.last_workout_date IS
'Date of the most recent completed workout';

COMMENT ON FUNCTION calculate_workout_streak(UUID) IS
'Calculates current and longest workout streaks for a user based on completed workouts';

COMMENT ON FUNCTION update_user_streak(UUID) IS
'Updates the streak fields in the profiles table for a user';

COMMENT ON FUNCTION trigger_update_streak() IS
'Trigger function that updates streak when a workout is completed';
