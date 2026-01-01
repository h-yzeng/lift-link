-- Create sync_queue table for tracking pending sync operations
CREATE TABLE IF NOT EXISTS public.sync_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation_type TEXT NOT NULL, -- 'create', 'update', 'delete'
  entity_type TEXT NOT NULL, -- 'workout', 'set', 'exercise', etc.
  entity_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 5,
  next_retry_at TIMESTAMP WITH TIME ZONE,
  last_error TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX idx_sync_queue_user_id ON public.sync_queue(user_id);

-- Create index on next_retry_at for retry queries
CREATE INDEX idx_sync_queue_next_retry ON public.sync_queue(next_retry_at) WHERE next_retry_at IS NOT NULL;

-- Create index on created_at for ordering
CREATE INDEX idx_sync_queue_created_at ON public.sync_queue(created_at);

-- Create composite index for pending operations query
CREATE INDEX idx_sync_queue_pending ON public.sync_queue(user_id, next_retry_at) WHERE next_retry_at IS NOT NULL OR retry_count = 0;

-- Enable RLS
ALTER TABLE public.sync_queue ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own sync queue items
CREATE POLICY sync_queue_select_own
  ON public.sync_queue
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own sync queue items
CREATE POLICY sync_queue_insert_own
  ON public.sync_queue
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own sync queue items
CREATE POLICY sync_queue_update_own
  ON public.sync_queue
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own sync queue items
CREATE POLICY sync_queue_delete_own
  ON public.sync_queue
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_sync_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER sync_queue_updated_at_trigger
  BEFORE UPDATE ON public.sync_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_sync_queue_updated_at();

-- Function to clean up old completed sync queue items (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_sync_queue()
RETURNS void AS $$
BEGIN
  DELETE FROM public.sync_queue
  WHERE retry_count >= max_retries
  AND updated_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE public.sync_queue IS 'Queue for tracking pending sync operations with retry logic';
COMMENT ON COLUMN public.sync_queue.operation_type IS 'Type of operation: create, update, delete';
COMMENT ON COLUMN public.sync_queue.entity_type IS 'Type of entity: workout, set, exercise, etc.';
COMMENT ON COLUMN public.sync_queue.entity_id IS 'ID of the entity being synced';
COMMENT ON COLUMN public.sync_queue.payload IS 'JSON payload containing the data to sync';
COMMENT ON COLUMN public.sync_queue.retry_count IS 'Number of retry attempts made';
COMMENT ON COLUMN public.sync_queue.max_retries IS 'Maximum number of retries allowed';
COMMENT ON COLUMN public.sync_queue.next_retry_at IS 'Timestamp when the next retry should occur';
COMMENT ON COLUMN public.sync_queue.last_error IS 'Last error message if retry failed';
