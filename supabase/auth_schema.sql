-- ============================================
-- YAPP AUTH SCHEMA
-- Run this in the NEW Supabase project
-- ============================================

-- 1. ADJECTIVES TABLE
CREATE TABLE adjectives (
  id SERIAL PRIMARY KEY,
  word TEXT NOT NULL UNIQUE
);

-- 2. NOUNS TABLE
CREATE TABLE nouns (
  id SERIAL PRIMARY KEY,
  word TEXT NOT NULL UNIQUE
);

-- 3. PROFILES TABLE
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
  avatar_emoji TEXT NOT NULL DEFAULT '🦊',
  avatar_color TEXT NOT NULL DEFAULT '#FF3C5F',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

ALTER TABLE adjectives ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Adjectives are publicly readable" ON adjectives FOR SELECT USING (true);

ALTER TABLE nouns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Nouns are publicly readable" ON nouns FOR SELECT USING (true);

-- 4. FUNCTION: get_random_usernames
CREATE OR REPLACE FUNCTION get_random_usernames()
RETURNS TEXT[] AS $$
DECLARE
  adj_words TEXT[];
  noun_words TEXT[];
  result TEXT[];
  i INT;
BEGIN
  SELECT ARRAY_AGG(word) INTO adj_words
  FROM (SELECT word FROM adjectives ORDER BY RANDOM() LIMIT 10) t;

  SELECT ARRAY_AGG(word) INTO noun_words
  FROM (SELECT word FROM nouns ORDER BY RANDOM() LIMIT 10) t;

  result := ARRAY[]::TEXT[];
  FOR i IN 1..10 LOOP
    result := result || (adj_words[i] || '_' || noun_words[i]);
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 5. SEED DATA: Adjectives
INSERT INTO adjectives (word) VALUES
('silent'), ('cosmic'), ('ghost'), ('neon'), ('void'),
('chaos'), ('rogue'), ('turbo'), ('blaze'), ('static'),
('wild'), ('dark'), ('solar'), ('lunar'), ('cyber'),
('frozen'), ('savage'), ('toxic'), ('hyper'), ('ultra'),
('stealth'), ('phantom'), ('atomic'), ('mystic'), ('ancient'),
('electric'), ('brutal'), ('crispy'), ('dizzy'), ('epic');

-- 6. SEED DATA: Nouns
INSERT INTO nouns (word) VALUES
('gecko'), ('pickle'), ('taco'), ('muffin'), ('panda'),
('possum'), ('pretzel'), ('biscuit'), ('noodle'), ('llama'),
('penguin'), ('waffle'), ('burrito'), ('goblin'), ('wizard'),
('dragon'), ('phoenix'), ('titan'), ('viper'), ('falcon'),
('raccoon'), ('koala'), ('sloth'), ('ferret'), ('otter'),
('badger'), ('mongoose'), ('iguana'), ('salamander'), ('platypus');
