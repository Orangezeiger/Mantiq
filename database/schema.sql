-- =============================================================
-- Mantiq – Datenbankschema (PostgreSQL)
-- =============================================================


-- -------------------------------------------------------------
-- Aufgabentypen (Lookup-Tabelle, wird einmalig befüllt)
-- -------------------------------------------------------------
CREATE TABLE task_types (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
    -- Werte: SINGLE_CHOICE, MULTIPLE_CHOICE, MATCHING,
    --        NUMBER_LINE, FILL_BLANK, SORTING, TRUE_FALSE
);

-- Standardwerte einfügen
INSERT INTO task_types (name) VALUES
    ('SINGLE_CHOICE'),    -- Einzelauswahl
    ('MULTIPLE_CHOICE'),  -- Mehrfachauswahl
    ('MATCHING'),         -- Verbinden
    ('NUMBER_LINE'),      -- Zahlenstrahl
    ('FILL_BLANK'),       -- Lückentext
    ('SORTING'),          -- Sortieren
    ('TRUE_FALSE');       -- Wahr / Falsch


-- -------------------------------------------------------------
-- Nutzer
-- -------------------------------------------------------------
CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------------------------------------------
-- Fortschrittsbäume (ein Baum pro Fach / Thema)
-- -------------------------------------------------------------
CREATE TABLE trees (
    id          SERIAL PRIMARY KEY,
    user_id     INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------------------------------------------
-- Schritte innerhalb eines Baums (Knoten im Duolingo-Pfad)
-- -------------------------------------------------------------
CREATE TABLE steps (
    id         SERIAL PRIMARY KEY,
    tree_id    INT          NOT NULL REFERENCES trees(id) ON DELETE CASCADE,
    title      VARCHAR(255) NOT NULL,
    position   INT          NOT NULL,  -- Reihenfolge im Baum (0-basiert)
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------------------------------------------
-- Aufgaben innerhalb eines Schritts
-- -------------------------------------------------------------
CREATE TABLE tasks (
    id           SERIAL PRIMARY KEY,
    step_id      INT  NOT NULL REFERENCES steps(id) ON DELETE CASCADE,
    task_type_id INT  NOT NULL REFERENCES task_types(id),
    question     TEXT NOT NULL,
    position     INT  NOT NULL,  -- Reihenfolge innerhalb des Schritts

    -- Nur für Zahlenstrahl (NUMBER_LINE):
    number_min     DECIMAL,
    number_max     DECIMAL,
    number_correct DECIMAL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------------------------------------------
-- Antwortoptionen einer Aufgabe
--
-- Wird genutzt für:
--   SINGLE_CHOICE   – mehrere Optionen, is_correct = true bei einer
--   MULTIPLE_CHOICE – mehrere Optionen, is_correct = true bei mehreren
--   MATCHING        – je zwei Zeilen bilden ein Paar (match_group gleich)
--   FILL_BLANK      – eine Zeile pro Lücke, is_correct = true
--   SORTING         – alle Elemente, position = korrekte Reihenfolge
--   TRUE_FALSE      – zwei Zeilen ("Wahr" / "Falsch"), is_correct markiert die richtige
-- -------------------------------------------------------------
CREATE TABLE task_options (
    id          SERIAL PRIMARY KEY,
    task_id     INT     NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    option_text TEXT    NOT NULL,
    is_correct  BOOLEAN NOT NULL DEFAULT FALSE,
    position    INT,         -- korrekte Reihenfolge (für SORTING)
    match_group INT          -- Gruppe für zusammengehörige Paare (für MATCHING)
);


-- -------------------------------------------------------------
-- Nutzer-Fortschritt (welche Schritte wurden abgeschlossen)
-- -------------------------------------------------------------
CREATE TABLE user_progress (
    id           SERIAL PRIMARY KEY,
    user_id      INT       NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    step_id      INT       NOT NULL REFERENCES steps(id)  ON DELETE CASCADE,
    completed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (user_id, step_id)  -- jeder Schritt nur einmal pro Nutzer
);


-- -------------------------------------------------------------
-- Indizes für häufige Abfragen
-- -------------------------------------------------------------
CREATE INDEX idx_trees_user       ON trees         (user_id);
CREATE INDEX idx_steps_tree       ON steps         (tree_id);
CREATE INDEX idx_tasks_step       ON tasks         (step_id);
CREATE INDEX idx_options_task     ON task_options  (task_id);
CREATE INDEX idx_progress_user    ON user_progress (user_id);
