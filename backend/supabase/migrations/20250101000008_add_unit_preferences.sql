-- Add unit preference to profiles
ALTER TABLE public.profiles
ADD COLUMN preferred_units TEXT NOT NULL DEFAULT 'imperial'
CHECK (preferred_units IN ('imperial', 'metric'));

-- Add comment
COMMENT ON COLUMN public.profiles.preferred_units IS 'User''s preferred unit system: imperial (lbs, ft, in) or metric (kg, cm)';
