-- Create workout_sessions table
CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    notes TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ, -- NULL if workout is in progress
    duration_minutes INTEGER, -- Calculated: (completed_at - started_at) in minutes
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_started_at ON workout_sessions(started_at DESC);
CREATE INDEX idx_workout_sessions_completed_at ON workout_sessions(completed_at DESC);

-- Updated_at trigger
CREATE TRIGGER update_workout_sessions_updated_at
    BEFORE UPDATE ON workout_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create exercise_performances table (junction between workouts and exercises)
CREATE TABLE exercise_performances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL, -- Order of exercise in workout
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_exercise_order_per_workout UNIQUE (workout_session_id, order_index)
);

-- Indexes
CREATE INDEX idx_exercise_performances_workout ON exercise_performances(workout_session_id);
CREATE INDEX idx_exercise_performances_exercise ON exercise_performances(exercise_id);

-- Updated_at trigger
CREATE TRIGGER update_exercise_performances_updated_at
    BEFORE UPDATE ON exercise_performances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
