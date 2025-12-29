-- Enable Row Level Security on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_performances ENABLE ROW LEVEL SECURITY;
ALTER TABLE sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can view profiles of accepted friends
CREATE POLICY "Users can view friends profiles"
    ON profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM friendships
            WHERE status = 'accepted'
            AND (
                (requester_id = auth.uid() AND addressee_id = profiles.id)
                OR (addressee_id = auth.uid() AND requester_id = profiles.id)
            )
        )
    );

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Users can insert their own profile (handled by trigger, but policy needed)
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- EXERCISES POLICIES
-- ============================================================================

-- Everyone can view system exercises (created_by IS NULL)
CREATE POLICY "Anyone can view system exercises"
    ON exercises FOR SELECT
    USING (created_by IS NULL);

-- Users can view their own custom exercises
CREATE POLICY "Users can view own custom exercises"
    ON exercises FOR SELECT
    USING (created_by = auth.uid());

-- Users can create custom exercises
CREATE POLICY "Users can create custom exercises"
    ON exercises FOR INSERT
    WITH CHECK (created_by = auth.uid() AND is_custom = TRUE);

-- Users can update their own custom exercises
CREATE POLICY "Users can update own custom exercises"
    ON exercises FOR UPDATE
    USING (created_by = auth.uid() AND is_custom = TRUE)
    WITH CHECK (created_by = auth.uid() AND is_custom = TRUE);

-- Users can delete their own custom exercises
CREATE POLICY "Users can delete own custom exercises"
    ON exercises FOR DELETE
    USING (created_by = auth.uid() AND is_custom = TRUE);

-- ============================================================================
-- WORKOUT_SESSIONS POLICIES
-- ============================================================================

-- Users can view their own workouts
CREATE POLICY "Users can view own workouts"
    ON workout_sessions FOR SELECT
    USING (user_id = auth.uid());

-- Users can view accepted friends' workouts
CREATE POLICY "Users can view friends workouts"
    ON workout_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM friendships
            WHERE status = 'accepted'
            AND (
                (requester_id = auth.uid() AND addressee_id = workout_sessions.user_id)
                OR (addressee_id = auth.uid() AND requester_id = workout_sessions.user_id)
            )
        )
    );

-- Users can create their own workouts
CREATE POLICY "Users can create own workouts"
    ON workout_sessions FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can update their own workouts
CREATE POLICY "Users can update own workouts"
    ON workout_sessions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Users can delete their own workouts
CREATE POLICY "Users can delete own workouts"
    ON workout_sessions FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================================
-- EXERCISE_PERFORMANCES POLICIES
-- ============================================================================

-- Users can view exercise performances from their own workouts
CREATE POLICY "Users can view own exercise performances"
    ON exercise_performances FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM workout_sessions
            WHERE workout_sessions.id = exercise_performances.workout_session_id
            AND workout_sessions.user_id = auth.uid()
        )
    );

-- Users can view exercise performances from friends' workouts
CREATE POLICY "Users can view friends exercise performances"
    ON exercise_performances FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM workout_sessions ws
            JOIN friendships f ON (
                f.status = 'accepted'
                AND (
                    (f.requester_id = auth.uid() AND f.addressee_id = ws.user_id)
                    OR (f.addressee_id = auth.uid() AND f.requester_id = ws.user_id)
                )
            )
            WHERE ws.id = exercise_performances.workout_session_id
        )
    );

-- Users can create exercise performances in their own workouts
CREATE POLICY "Users can create own exercise performances"
    ON exercise_performances FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM workout_sessions
            WHERE workout_sessions.id = exercise_performances.workout_session_id
            AND workout_sessions.user_id = auth.uid()
        )
    );

-- Users can update exercise performances in their own workouts
CREATE POLICY "Users can update own exercise performances"
    ON exercise_performances FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM workout_sessions
            WHERE workout_sessions.id = exercise_performances.workout_session_id
            AND workout_sessions.user_id = auth.uid()
        )
    );

-- Users can delete exercise performances from their own workouts
CREATE POLICY "Users can delete own exercise performances"
    ON exercise_performances FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM workout_sessions
            WHERE workout_sessions.id = exercise_performances.workout_session_id
            AND workout_sessions.user_id = auth.uid()
        )
    );

-- ============================================================================
-- SETS POLICIES
-- ============================================================================

-- Users can view sets from their own exercise performances
CREATE POLICY "Users can view own sets"
    ON sets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exercise_performances ep
            JOIN workout_sessions ws ON ws.id = ep.workout_session_id
            WHERE ep.id = sets.exercise_performance_id
            AND ws.user_id = auth.uid()
        )
    );

-- Users can view sets from friends' exercise performances
CREATE POLICY "Users can view friends sets"
    ON sets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exercise_performances ep
            JOIN workout_sessions ws ON ws.id = ep.workout_session_id
            JOIN friendships f ON (
                f.status = 'accepted'
                AND (
                    (f.requester_id = auth.uid() AND f.addressee_id = ws.user_id)
                    OR (f.addressee_id = auth.uid() AND f.requester_id = ws.user_id)
                )
            )
            WHERE ep.id = sets.exercise_performance_id
        )
    );

-- Users can create sets in their own exercise performances
CREATE POLICY "Users can create own sets"
    ON sets FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM exercise_performances ep
            JOIN workout_sessions ws ON ws.id = ep.workout_session_id
            WHERE ep.id = sets.exercise_performance_id
            AND ws.user_id = auth.uid()
        )
    );

-- Users can update sets in their own exercise performances
CREATE POLICY "Users can update own sets"
    ON sets FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM exercise_performances ep
            JOIN workout_sessions ws ON ws.id = ep.workout_session_id
            WHERE ep.id = sets.exercise_performance_id
            AND ws.user_id = auth.uid()
        )
    );

-- Users can delete sets from their own exercise performances
CREATE POLICY "Users can delete own sets"
    ON sets FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM exercise_performances ep
            JOIN workout_sessions ws ON ws.id = ep.workout_session_id
            WHERE ep.id = sets.exercise_performance_id
            AND ws.user_id = auth.uid()
        )
    );

-- ============================================================================
-- FRIENDSHIPS POLICIES
-- ============================================================================

-- Users can view friendships where they are involved
CREATE POLICY "Users can view own friendships"
    ON friendships FOR SELECT
    USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- Users can create friend requests
CREATE POLICY "Users can create friend requests"
    ON friendships FOR INSERT
    WITH CHECK (requester_id = auth.uid() AND status = 'pending');

-- Users can update friendships where they are the addressee (accept/reject)
CREATE POLICY "Addressees can update friendship status"
    ON friendships FOR UPDATE
    USING (addressee_id = auth.uid())
    WITH CHECK (addressee_id = auth.uid());

-- Users can delete friendships where they are involved
CREATE POLICY "Users can delete own friendships"
    ON friendships FOR DELETE
    USING (requester_id = auth.uid() OR addressee_id = auth.uid());
