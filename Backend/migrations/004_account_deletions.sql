-- Migration: Account Deletions Table
-- Date: 2025-10-17
-- Purpose: Track account deletion requests for GDPR/CCPA compliance

-- Create account_deletions table
CREATE TABLE IF NOT EXISTS account_deletions (
    id VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'failed'
    error_message TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    estimated_completion_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_account_deletions_user_id ON account_deletions(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletions_status ON account_deletions(status);
CREATE INDEX IF NOT EXISTS idx_account_deletions_requested_at ON account_deletions(requested_at);

-- Create function to auto-update started_at timestamp
CREATE OR REPLACE FUNCTION update_deletion_started_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'in_progress' AND OLD.status != 'in_progress' THEN
        NEW.started_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating started_at
DROP TRIGGER IF EXISTS trigger_update_deletion_started ON account_deletions;
CREATE TRIGGER trigger_update_deletion_started
    BEFORE UPDATE ON account_deletions
    FOR EACH ROW
    EXECUTE FUNCTION update_deletion_started_timestamp();

-- Add comments for documentation
COMMENT ON TABLE account_deletions IS 'Tracks account deletion requests for GDPR/CCPA compliance';
COMMENT ON COLUMN account_deletions.id IS 'Unique deletion request ID (del_timestamp_userid)';
COMMENT ON COLUMN account_deletions.status IS 'Deletion status: pending, in_progress, completed, failed';
COMMENT ON COLUMN account_deletions.estimated_completion_at IS 'Estimated completion time (7 days from request)';
