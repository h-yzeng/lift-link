-- Create exercises table (predefined exercise library)
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    muscle_group TEXT NOT NULL, -- chest, back, legs, shoulders, arms, core
    equipment_type TEXT, -- barbell, dumbbell, machine, bodyweight, cable
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NULL for system exercises
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure system exercises have unique names, custom exercises unique per user
    CONSTRAINT unique_system_exercise UNIQUE NULLS NOT DISTINCT (name, created_by)
);

-- Indexes
CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_created_by ON exercises(created_by);

-- Updated_at trigger
CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert common exercises
INSERT INTO exercises (name, description, muscle_group, equipment_type, is_custom) VALUES
    ('Bench Press', 'Lie on bench, lower bar to chest, press up', 'chest', 'barbell', FALSE),
    ('Squat', 'Bar on back, squat down to parallel, stand up', 'legs', 'barbell', FALSE),
    ('Deadlift', 'Bar on floor, hinge at hips, lift to standing', 'back', 'barbell', FALSE),
    ('Overhead Press', 'Bar at shoulders, press overhead', 'shoulders', 'barbell', FALSE),
    ('Barbell Row', 'Bent over, row bar to lower chest', 'back', 'barbell', FALSE),
    ('Pull-up', 'Hang from bar, pull chin over bar', 'back', 'bodyweight', FALSE),
    ('Dip', 'Support on bars, lower body, push up', 'chest', 'bodyweight', FALSE),
    ('Leg Press', 'Push platform away with feet', 'legs', 'machine', FALSE),
    ('Lat Pulldown', 'Pull bar down to upper chest', 'back', 'cable', FALSE),
    ('Dumbbell Curl', 'Curl dumbbells from sides to shoulders', 'arms', 'dumbbell', FALSE),
    ('Tricep Pushdown', 'Push cable attachment down, extend arms', 'arms', 'cable', FALSE),
    ('Leg Curl', 'Curl weight toward glutes', 'legs', 'machine', FALSE),
    ('Leg Extension', 'Extend legs against resistance', 'legs', 'machine', FALSE),
    ('Lateral Raise', 'Raise dumbbells to sides', 'shoulders', 'dumbbell', FALSE),
    ('Plank', 'Hold body in straight line on forearms', 'core', 'bodyweight', FALSE),
    ('Romanian Deadlift', 'Hinge at hips, lower bar along legs', 'legs', 'barbell', FALSE),
    ('Incline Bench Press', 'Bench at incline, press bar up', 'chest', 'barbell', FALSE),
    ('Cable Fly', 'Bring cable handles together in arc', 'chest', 'cable', FALSE),
    ('Face Pull', 'Pull rope to face, external rotation', 'shoulders', 'cable', FALSE),
    ('Hip Thrust', 'Back on bench, drive hips up with bar', 'legs', 'barbell', FALSE);
