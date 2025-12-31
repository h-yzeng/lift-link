-- Add nickname field to friendships table
-- This allows users to give their friends custom nicknames

ALTER TABLE friendships
ADD COLUMN requester_nickname TEXT,
ADD COLUMN addressee_nickname TEXT;

-- requester_nickname: Nickname that the requester gives to the addressee
-- addressee_nickname: Nickname that the addressee gives to the requester

COMMENT ON COLUMN friendships.requester_nickname IS 'Nickname given by requester to addressee';
COMMENT ON COLUMN friendships.addressee_nickname IS 'Nickname given by addressee to requester';
