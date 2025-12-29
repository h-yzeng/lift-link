-- Create sets table
CREATE TABLE sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_performance_id UUID NOT NULL REFERENCES exercise_performances(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL, -- 1, 2, 3, etc.
    reps INTEGER NOT NULL CHECK (reps > 0),
    weight_kg DECIMAL(6,2) NOT NULL CHECK (weight_kg >= 0), -- Max 9999.99 kg
    is_warmup BOOLEAN NOT NULL DEFAULT FALSE,
    is_dropset BOOLEAN NOT NULL DEFAULT FALSE,
    rpe DECIMAL(3,1) CHECK (rpe IS NULL OR (rpe >= 0 AND rpe <= 10)), -- Rate of Perceived Exertion (0-10)
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_set_per_performance UNIQUE (exercise_performance_id, set_number)
);

-- Indexes
CREATE INDEX idx_sets_exercise_performance ON sets(exercise_performance_id);
CREATE INDEX idx_sets_set_number ON sets(set_number);

-- Updated_at trigger
CREATE TRIGGER update_sets_updated_at
    BEFORE UPDATE ON sets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Note: 1RM is NEVER stored in database - calculated client-side only
-- Formula: weight * (1 + reps/30) - Epley Formula
