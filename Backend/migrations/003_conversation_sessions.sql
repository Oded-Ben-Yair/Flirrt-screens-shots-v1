-- Migration: Conversation Sessions for Multi-Screenshot Context
-- Date: 2025-10-17
-- Purpose: Track conversation sessions for intelligent multi-screenshot suggestions

-- Create conversation_sessions table
CREATE TABLE IF NOT EXISTS conversation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    conversation_id VARCHAR(255), -- External conversation ID (e.g., dating app chat ID)
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'closed'
    screenshot_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Add session_id to screenshots table
ALTER TABLE screenshots
ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES conversation_sessions(id) ON DELETE SET NULL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversation_sessions_user_id ON conversation_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_sessions_updated_at ON conversation_sessions(updated_at);
CREATE INDEX IF NOT EXISTS idx_conversation_sessions_status ON conversation_sessions(status);
CREATE INDEX IF NOT EXISTS idx_screenshots_session_id ON screenshots(session_id);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_conversation_session_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS trigger_update_conversation_session_timestamp ON conversation_sessions;
CREATE TRIGGER trigger_update_conversation_session_timestamp
    BEFORE UPDATE ON conversation_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_session_timestamp();

-- Add comments for documentation
COMMENT ON TABLE conversation_sessions IS 'Tracks conversation sessions for multi-screenshot context';
COMMENT ON COLUMN conversation_sessions.conversation_id IS 'External dating app conversation identifier (optional)';
COMMENT ON COLUMN conversation_sessions.screenshot_count IS 'Number of screenshots in this session';
COMMENT ON COLUMN conversation_sessions.status IS 'Session status: active (within 30 min), closed (inactive)';
