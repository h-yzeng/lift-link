-- Create weight_logs table for tracking bodyweight over time
CREATE TABLE IF NOT EXISTS public.weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 1000),
  unit TEXT NOT NULL DEFAULT 'kg' CHECK (unit IN ('kg', 'lbs')),
  notes TEXT,
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX idx_weight_logs_user_id ON public.weight_logs(user_id);
CREATE INDEX idx_weight_logs_logged_at ON public.weight_logs(logged_at);
CREATE INDEX idx_weight_logs_user_logged ON public.weight_logs(user_id, logged_at DESC);

-- Enable RLS
ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own weight logs
CREATE POLICY weight_logs_select_own
  ON public.weight_logs
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own weight logs
CREATE POLICY weight_logs_insert_own
  ON public.weight_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own weight logs
CREATE POLICY weight_logs_update_own
  ON public.weight_logs
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own weight logs
CREATE POLICY weight_logs_delete_own
  ON public.weight_logs
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_weight_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER weight_logs_updated_at_trigger
  BEFORE UPDATE ON public.weight_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_weight_logs_updated_at();

COMMENT ON TABLE public.weight_logs IS 'User bodyweight logs for tracking weight over time';
COMMENT ON COLUMN public.weight_logs.weight IS 'Bodyweight value (must be > 0 and < 1000)';
COMMENT ON COLUMN public.weight_logs.unit IS 'Unit of measurement: kg or lbs';
COMMENT ON COLUMN public.weight_logs.logged_at IS 'When the weight was measured (can be backdated)';
