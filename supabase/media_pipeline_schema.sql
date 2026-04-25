-- ============================================
-- YAPP MEDIA PIPELINE SCHEMA
-- Voice-first social media database structure
-- ============================================

-- 1. MEDIA FILES TABLE
-- Tracks all uploaded media (audio, video, images)
-- Stores both raw uploads and processed versions
CREATE TABLE media_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Ownership
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- File metadata
  media_type TEXT NOT NULL CHECK (media_type IN ('audio', 'video', 'image')),
  file_size_bytes BIGINT NOT NULL,
  duration_seconds DECIMAL(10,2), -- For audio/video only
  
  -- Storage paths (R2 keys)
  raw_file_key TEXT NOT NULL,      -- Original upload: raw/audio/{user_id}/{timestamp}_{uuid}.ogg
  processed_file_key TEXT,         -- Cleaned version: processed/audio/{user_id}/{timestamp}_{uuid}_clean.ogg
  
  -- Public URLs (CDN)
  raw_url TEXT,
  processed_url TEXT,
  
  -- Processing status
  processing_status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  processing_error TEXT,           -- Error message if failed
  processing_started_at TIMESTAMPTZ,
  processing_completed_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast queries
CREATE INDEX idx_media_files_user_id ON media_files(user_id);
CREATE INDEX idx_media_files_status ON media_files(processing_status);
CREATE INDEX idx_media_files_created ON media_files(created_at DESC);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER media_files_updated_at 
  BEFORE UPDATE ON media_files 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- 2. VOICE FILTERS TABLE
-- Stores different filter versions of the same audio
CREATE TABLE voice_filters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Links to original media
  media_file_id UUID NOT NULL REFERENCES media_files(id) ON DELETE CASCADE,
  
  -- Filter details
  filter_type TEXT NOT NULL CHECK (filter_type IN ('normal', 'chipmunk', 'deep_voice', 'robot')),
  
  -- Storage
  processed_file_key TEXT NOT NULL,  -- processed/audio/{user_id}/{timestamp}_{uuid}_{filter}.ogg
  processed_url TEXT,
  file_size_bytes BIGINT NOT NULL,
  
  -- Processing
  processing_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  processing_error TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_voice_filters_media_id ON voice_filters(media_file_id);
CREATE INDEX idx_voice_filters_status ON voice_filters(processing_status);

-- Prevent duplicate filters
CREATE UNIQUE INDEX idx_voice_filters_unique 
  ON voice_filters(media_file_id, filter_type);

CREATE TRIGGER voice_filters_updated_at 
  BEFORE UPDATE ON voice_filters 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- 3. YAPS TABLE
-- The actual posts/yaps that users see in feed
CREATE TABLE yaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Ownership
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Content
  media_file_id UUID NOT NULL REFERENCES media_files(id) ON DELETE CASCADE,
  selected_filter TEXT NOT NULL DEFAULT 'normal' 
    CHECK (selected_filter IN ('normal', 'chipmunk', 'deep_voice', 'robot')),
  
  -- Auto-generated transcript (for discoverability)
  transcript TEXT,
  transcript_confidence DECIMAL(3,2), -- Whisper API confidence score (0.00-1.00)
  
  -- Engagement
  play_count BIGINT NOT NULL DEFAULT 0,
  like_count BIGINT NOT NULL DEFAULT 0,
  reply_count BIGINT NOT NULL DEFAULT 0,
  reshare_count BIGINT NOT NULL DEFAULT 0,
  
  -- Thread structure (for replies)
  parent_yap_id UUID REFERENCES yaps(id) ON DELETE CASCADE, -- NULL if root yap
  thread_root_id UUID REFERENCES yaps(id) ON DELETE CASCADE, -- Points to top of thread
  
  -- Visibility
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for feed queries
CREATE INDEX idx_yaps_user_id ON yaps(user_id);
CREATE INDEX idx_yaps_created_desc ON yaps(created_at DESC) WHERE is_deleted = FALSE;
CREATE INDEX idx_yaps_parent ON yaps(parent_yap_id) WHERE parent_yap_id IS NOT NULL;
CREATE INDEX idx_yaps_thread ON yaps(thread_root_id) WHERE thread_root_id IS NOT NULL;
CREATE INDEX idx_yaps_media ON yaps(media_file_id);

-- Full-text search on transcripts
CREATE INDEX idx_yaps_transcript_search ON yaps USING gin(to_tsvector('english', transcript));

CREATE TRIGGER yaps_updated_at 
  BEFORE UPDATE ON yaps 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- 4. ROW LEVEL SECURITY (RLS)

-- Media files: Users can only see their own
ALTER TABLE media_files ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own media" ON media_files FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own media" ON media_files FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own media" ON media_files FOR UPDATE USING (auth.uid() = user_id);

-- Voice filters: Users can only see their own
ALTER TABLE voice_filters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own filters" ON voice_filters FOR SELECT 
  USING (EXISTS (SELECT 1 FROM media_files WHERE media_files.id = voice_filters.media_file_id AND media_files.user_id = auth.uid()));

-- Yaps: Everyone can view, only owner can insert/update/delete
ALTER TABLE yaps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view non-deleted yaps" ON yaps FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "Users can insert own yaps" ON yaps FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own yaps" ON yaps FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own yaps" ON yaps FOR DELETE USING (auth.uid() = user_id);


-- 5. HELPER FUNCTIONS

-- Increment play count (called when user plays a yap)
CREATE OR REPLACE FUNCTION increment_play_count(yap_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE yaps SET play_count = play_count + 1 WHERE id = yap_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Soft delete yap
CREATE OR REPLACE FUNCTION soft_delete_yap(yap_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE yaps 
  SET is_deleted = TRUE, deleted_at = NOW() 
  WHERE id = yap_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
