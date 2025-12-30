-- Add exercise_name column to exercise_performances table for denormalized display
ALTER TABLE exercise_performances
ADD COLUMN exercise_name TEXT NOT NULL DEFAULT '';

-- Add comment explaining the denormalization
COMMENT ON COLUMN exercise_performances.exercise_name IS 'Denormalized exercise name for display purposes. Avoids joins when loading workout data.';
