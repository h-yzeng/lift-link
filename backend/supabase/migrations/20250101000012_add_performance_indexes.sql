-- Migration: Add Performance Indexes
-- Description: Add indexes to optimize frequently queried columns for better performance
-- Date: 2025-01-01

-- Index on workout_sessions for user-specific workout history queries
-- Optimizes: SELECT * FROM workout_sessions WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_created
ON workout_sessions(user_id, created_at DESC);

-- Index on workout_sessions for completion time queries (analytics, streaks)
-- Optimizes: SELECT * FROM workout_sessions WHERE user_id = ? AND completed_at IS NOT NULL
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_completed
ON workout_sessions(user_id, completed_at DESC)
WHERE completed_at IS NOT NULL;

-- Index on exercise_performances for workout detail lookups
-- Optimizes: SELECT * FROM exercise_performances WHERE workout_session_id = ?
CREATE INDEX IF NOT EXISTS idx_exercise_performances_workout
ON exercise_performances(workout_session_id);

-- Index on exercise_performances for exercise-specific queries
-- Optimizes: Exercise history queries by exercise_id
CREATE INDEX IF NOT EXISTS idx_exercise_performances_exercise
ON exercise_performances(exercise_id);

-- Index on sets for exercise performance lookups
-- Optimizes: SELECT * FROM sets WHERE exercise_performance_id = ?
CREATE INDEX IF NOT EXISTS idx_sets_exercise_performance
ON sets(exercise_performance_id);

-- Index on exercises for user custom exercises
-- Optimizes: SELECT * FROM exercises WHERE user_id = ? AND is_custom = true
CREATE INDEX IF NOT EXISTS idx_exercises_user_custom
ON exercises(user_id, is_custom)
WHERE is_custom = true;

-- Index on friendships for user-specific friend queries
-- Optimizes: SELECT * FROM friendships WHERE user_id = ? AND status = 'accepted'
CREATE INDEX IF NOT EXISTS idx_friendships_user_status
ON friendships(user_id, status);

-- Index on friendships for friend request lookups
-- Optimizes: SELECT * FROM friendships WHERE friend_id = ? AND status = 'pending'
CREATE INDEX IF NOT EXISTS idx_friendships_friend_status
ON friendships(friend_id, status);

-- Composite index for activity feed queries
-- Optimizes: Finding workouts by friends for activity feed
CREATE INDEX IF NOT EXISTS idx_workout_sessions_completed_at
ON workout_sessions(completed_at DESC)
WHERE completed_at IS NOT NULL;

COMMENT ON INDEX idx_workout_sessions_user_created IS
'Optimizes user workout history queries ordered by creation date';

COMMENT ON INDEX idx_workout_sessions_user_completed IS
'Optimizes completed workout queries for analytics and streaks';

COMMENT ON INDEX idx_exercise_performances_workout IS
'Optimizes workout detail page loading';

COMMENT ON INDEX idx_exercise_performances_exercise IS
'Optimizes exercise history queries';

COMMENT ON INDEX idx_sets_exercise_performance IS
'Optimizes set loading for exercise performances';

COMMENT ON INDEX idx_exercises_user_custom IS
'Optimizes custom exercise filtering';

COMMENT ON INDEX idx_friendships_user_status IS
'Optimizes friend list queries';

COMMENT ON INDEX idx_friendships_friend_status IS
'Optimizes incoming friend request queries';

COMMENT ON INDEX idx_workout_sessions_completed_at IS
'Optimizes activity feed queries showing recent completed workouts';
