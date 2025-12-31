-- Allow users to search and view all profiles
-- This is necessary for the friend request system to work
-- Users need to be able to find other users to send friend requests

CREATE POLICY "Users can search all profiles"
    ON profiles FOR SELECT
    USING (true);

-- Note: This replaces the more restrictive policies, allowing all authenticated users
-- to view all profiles. Individual users still control what data is shared via their
-- profile settings (username, display_name, avatar_url, bio).
