-- ============================================
-- DAY 1 MIGRATION: POSTS + MEDIA EXTENSIONS
-- ============================================

-- STEP 1: Extend media_files for images/videos
ALTER TABLE media_files 
  ADD COLUMN width INT,
  ADD COLUMN height INT,
  ADD COLUMN thumbnail_file_key TEXT;

-- STEP 2: Fix media_files RLS (allow anyone to read for post display)
DROP POLICY "Users can view own media" ON media_files;
CREATE POLICY "Anyone can view media" ON media_files FOR SELECT USING (true);

-- STEP 3: Create posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Content
  content_type TEXT NOT NULL CHECK (content_type IN ('text', 'image', 'video', 'text_image', 'text_video')),
  text_content TEXT CHECK (LENGTH(text_content) <= 280),
  media_file_id UUID REFERENCES media_files(id) ON DELETE SET NULL,
  thumbnail_file_key TEXT,
  
  -- Engagement (denormalized for fast feed queries)
  yap_count INT NOT NULL DEFAULT 0,
  view_count BIGINT NOT NULL DEFAULT 0,
  hotness_score FLOAT NOT NULL DEFAULT 0,
  
  -- Moderation
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  is_removed BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for feed performance
CREATE INDEX idx_posts_hotness ON posts(hotness_score DESC) WHERE is_removed = FALSE;
CREATE INDEX idx_posts_created ON posts(created_at DESC) WHERE is_removed = FALSE;
CREATE INDEX idx_posts_user ON posts(user_id);

-- Auto-update timestamp
CREATE TRIGGER posts_updated_at 
  BEFORE UPDATE ON posts 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view non-removed posts" ON posts FOR SELECT USING (is_removed = FALSE);
CREATE POLICY "Users can insert own posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON posts FOR DELETE USING (auth.uid() = user_id);

-- STEP 4: Clean test yaps + add post_id
DELETE FROM yaps;

ALTER TABLE yaps ADD COLUMN post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE;
CREATE INDEX idx_yaps_post ON yaps(post_id);

-- STEP 5: Hotness score calculation (runs hourly via pg_cron)
CREATE OR REPLACE FUNCTION calculate_hotness_score(post_id UUID)
RETURNS FLOAT AS $$
DECLARE
  hours_old FLOAT;
  yaps INT;
  score FLOAT;
BEGIN
  SELECT 
    EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600,
    yap_count
  INTO hours_old, yaps
  FROM posts WHERE id = post_id;
  
  -- Formula: (yap_count + 1) * exp(-hours_old / 24)
  -- Decays over 24 hours, boosted by engagement
  score := (yaps + 1) * EXP(-hours_old / 24.0);
  
  RETURN score;
END;
$$ LANGUAGE plpgsql;

-- Update all posts hotness (call this hourly)
CREATE OR REPLACE FUNCTION update_all_hotness_scores()
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET hotness_score = calculate_hotness_score(id)
  WHERE is_removed = FALSE;
END;
$$ LANGUAGE plpgsql;

-- DONE: Schema ready for Week 2
