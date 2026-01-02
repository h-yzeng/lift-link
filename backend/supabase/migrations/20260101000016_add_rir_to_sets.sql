-- Add RIR (Reps in Reserve) field to sets table
-- RIR indicates how many more reps could have been performed
-- RIR of 0 = max effort (RPE 10), RIR of 1 = RPE 9.5, RIR of 2 = RPE 9, etc.

ALTER TABLE public.sets
ADD COLUMN rir INTEGER CHECK (rir IS NULL OR (rir >= 0 AND rir <= 10));

COMMENT ON COLUMN public.sets.rir IS 'Reps in Reserve - how many more reps could have been performed (0-10)';
