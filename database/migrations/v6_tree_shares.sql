CREATE TABLE IF NOT EXISTS tree_shares (
    id                  SERIAL PRIMARY KEY,
    tree_id             INTEGER NOT NULL REFERENCES trees(id) ON DELETE CASCADE,
    code                VARCHAR(10) NOT NULL UNIQUE,
    created_by_user_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);
