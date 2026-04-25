-- Additional helper function for reply counts
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION increment_reply_count(yap_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE yaps SET reply_count = reply_count + 1 WHERE id = yap_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
