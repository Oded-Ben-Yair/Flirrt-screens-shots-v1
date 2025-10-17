-- Migration: Gamification System
-- Date: 2025-10-17
-- Purpose: Add user stats and achievements for gamification system

-- Create user_stats table for tracking user progress
CREATE TABLE IF NOT EXISTS user_stats (
    user_id UUID PRIMARY KEY,
    messages_sent INTEGER DEFAULT 0,
    successful_conversations INTEGER DEFAULT 0,
    profiles_analyzed INTEGER DEFAULT 0,
    suggestions_generated INTEGER DEFAULT 0,
    refreshes_used INTEGER DEFAULT 0,
    high_confidence_used INTEGER DEFAULT 0,
    unique_tones_used INTEGER DEFAULT 0,
    daily_streak INTEGER DEFAULT 0,
    last_activity_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_confidence_sum INTEGER DEFAULT 0,
    total_confidence_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_stats_successful_conversations ON user_stats(successful_conversations);
CREATE INDEX IF NOT EXISTS idx_user_stats_daily_streak ON user_stats(daily_streak);
CREATE INDEX IF NOT EXISTS idx_user_stats_last_activity ON user_stats(last_activity_date);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_stats_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_update_user_stats_timestamp ON user_stats;
CREATE TRIGGER trigger_update_user_stats_timestamp
    BEFORE UPDATE ON user_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats_timestamp();

-- Add comments for documentation
COMMENT ON TABLE user_stats IS 'Tracks user progress for gamification system';
COMMENT ON COLUMN user_stats.messages_sent IS 'Total number of flirt suggestions sent';
COMMENT ON COLUMN user_stats.successful_conversations IS 'Number of conversations marked as successful (used for level calculation)';
COMMENT ON COLUMN user_stats.profiles_analyzed IS 'Number of dating profiles analyzed';
COMMENT ON COLUMN user_stats.suggestions_generated IS 'Total number of suggestions generated';
COMMENT ON COLUMN user_stats.refreshes_used IS 'Number of times refresh button was used';
COMMENT ON COLUMN user_stats.high_confidence_used IS 'Number of times suggestions with 90+ confidence were used';
COMMENT ON COLUMN user_stats.unique_tones_used IS 'Number of unique tone preferences tried';
COMMENT ON COLUMN user_stats.daily_streak IS 'Current daily streak (consecutive days using app)';
COMMENT ON COLUMN user_stats.last_activity_date IS 'Last time user was active';
COMMENT ON COLUMN user_stats.total_confidence_sum IS 'Sum of all confidence scores (for averaging)';
COMMENT ON COLUMN user_stats.total_confidence_count IS 'Count of suggestions used (for averaging)';

-- Create user_achievements table for tracking unlocked achievements
CREATE TABLE IF NOT EXISTS user_achievements (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    achievement_id VARCHAR(100) NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

-- Add comments for documentation
COMMENT ON TABLE user_achievements IS 'Tracks unlocked achievements for each user';
COMMENT ON COLUMN user_achievements.achievement_id IS 'Achievement identifier (e.g., first_message, ten_successes)';
COMMENT ON COLUMN user_achievements.unlocked_at IS 'Timestamp when achievement was unlocked';

-- Create view for easy level calculation
CREATE OR REPLACE VIEW user_levels AS
SELECT
    user_id,
    successful_conversations,
    FLOOR(successful_conversations / 5) + 1 as level,
    successful_conversations % 5 as progress_to_next,
    (FLOOR(successful_conversations / 5) + 1) * 5 as next_level_at,
    CASE
        WHEN FLOOR(successful_conversations / 5) + 1 = 1 THEN 'Beginner'
        WHEN FLOOR(successful_conversations / 5) + 1 <= 3 THEN 'Learner'
        WHEN FLOOR(successful_conversations / 5) + 1 <= 5 THEN 'Confident'
        WHEN FLOOR(successful_conversations / 5) + 1 <= 10 THEN 'Skilled'
        ELSE 'Expert'
    END as level_title
FROM user_stats;

-- Add comments for view
COMMENT ON VIEW user_levels IS 'Calculated user levels based on successful conversations';

-- Insert sample data for testing (optional - can be removed in production)
-- This helps with testing the gamification system
INSERT INTO user_stats (user_id, messages_sent, successful_conversations, profiles_analyzed, suggestions_generated)
SELECT id, 0, 0, 0, 0
FROM users
WHERE id NOT IN (SELECT user_id FROM user_stats)
ON CONFLICT (user_id) DO NOTHING;
