-- v7: last_reward_claimed_at column for weekly league rewards
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_reward_claimed_at TIMESTAMP;
