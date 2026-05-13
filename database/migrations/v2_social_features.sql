-- =============================================================
-- Mantiq – Migration v2: Social Features, Streak, Shop, Gruppen
-- =============================================================

-- Neue Spalten in der users-Tabelle
ALTER TABLE users ADD COLUMN display_name     VARCHAR(100);
ALTER TABLE users ADD COLUMN xp               INT          NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN coins            INT          NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN streak_days      INT          NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN streak_before_reset INT       NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN last_active_date DATE;
ALTER TABLE users ADD COLUMN subscription_plan VARCHAR(20) NOT NULL DEFAULT 'FREE';
ALTER TABLE users ADD COLUMN subscription_until TIMESTAMP;

-- Freundschaften (gerichtete Anfrage: user_id schickt an friend_id)
CREATE TABLE friendships (
    id         SERIAL PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id  INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status     VARCHAR(20)  NOT NULL DEFAULT 'PENDING',  -- PENDING | ACCEPTED
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, friend_id)
);
CREATE INDEX idx_friendships_user   ON friendships (user_id);
CREATE INDEX idx_friendships_friend ON friendships (friend_id);

-- Shop-Items (Katalog, wird einmalig befüllt)
CREATE TABLE items (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    cost        INT          NOT NULL,  -- in Coins
    item_type   VARCHAR(50)  NOT NULL   -- STREAK_FREEZE | DOUBLE_XP | COIN_BOOST
);

-- Inventar des Nutzers
CREATE TABLE user_items (
    id       SERIAL PRIMARY KEY,
    user_id  INT NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    item_id  INT NOT NULL REFERENCES items(id)  ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1,
    UNIQUE (user_id, item_id)
);
CREATE INDEX idx_user_items_user ON user_items (user_id);

-- Gruppen (Universitäten oder Module)
CREATE TABLE mantiq_groups (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    group_type  VARCHAR(20)  NOT NULL,  -- UNIVERSITY | MODULE
    description TEXT,
    invite_code VARCHAR(20)  UNIQUE,    -- kurzer Code zum Beitreten
    created_by  INT          NOT NULL REFERENCES users(id),
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_groups_created_by ON mantiq_groups (created_by);

-- Gruppenmitglieder
CREATE TABLE group_members (
    id        SERIAL PRIMARY KEY,
    group_id  INT         NOT NULL REFERENCES mantiq_groups(id) ON DELETE CASCADE,
    user_id   INT         NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
    role      VARCHAR(20) NOT NULL DEFAULT 'MEMBER',  -- ADMIN | MEMBER
    joined_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (group_id, user_id)
);
CREATE INDEX idx_group_members_group ON group_members (group_id);
CREATE INDEX idx_group_members_user  ON group_members (user_id);

-- Geteilte Bäume in Gruppen (Inhalt read-only für Mitglieder)
CREATE TABLE group_trees (
    id        SERIAL PRIMARY KEY,
    group_id  INT       NOT NULL REFERENCES mantiq_groups(id) ON DELETE CASCADE,
    tree_id   INT       NOT NULL REFERENCES trees(id)         ON DELETE CASCADE,
    shared_by INT       NOT NULL REFERENCES users(id),
    shared_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (group_id, tree_id)
);
CREATE INDEX idx_group_trees_group ON group_trees (group_id);

-- Standard-Items befüllen
INSERT INTO items (name, description, cost, item_type) VALUES
    ('Streak-Schild',  'Stellt deine verlorene Streak wieder her',    100, 'STREAK_FREEZE'),
    ('Doppel-XP',      'Verdoppelt deine XP für die nächste Session', 150, 'DOUBLE_XP'),
    ('Münzregen',      'Erhalte sofort 50 Bonus-Münzen',               80, 'COIN_BOOST');
