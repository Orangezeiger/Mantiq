-- v8: Demo-Nutzer und Freundschaften fuer Ranglisten-Test
-- Passwort fuer alle Demo-Nutzer: "demo123" (bcrypt hash)
-- $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza

INSERT INTO users (email, password_hash, display_name, first_name, last_name, xp, coins, streak_days)
VALUES
  -- Bronze (0–1499)
  ('lena.braun@demo.de',    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'LenaBraun',    'Lena',    'Braun',    320,   50, 3),
  ('tom.richter@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'TomRichter',   'Tom',     'Richter',  870,   80, 7),
  ('mia.wolf@demo.de',      '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'MiaWolf',      'Mia',     'Wolf',     1100, 120, 12),
  -- Silber (1500–4999)
  ('felix.bauer@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'FelixBauer',   'Felix',   'Bauer',    1800, 200, 15),
  ('sara.schulz@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'SaraSchulz',   'Sara',    'Schulz',   2500, 310, 21),
  ('jan.neumann@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'JanNeumann',   'Jan',     'Neumann',  3200, 450, 28),
  ('anna.klein@demo.de',    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'AnnaKlein',    'Anna',    'Klein',    4700, 600, 35),
  -- Gold (5000–9999)
  ('nico.Fischer@demo.de',  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'NicoFischer',  'Nico',    'Fischer',  5400, 750, 42),
  ('julia.weber@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'JuliaWeber',   'Julia',   'Weber',    6800, 900, 50),
  ('lukas.meyer@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'LukasMeyer',   'Lukas',   'Meyer',    8900, 1100, 60),
  -- Platin (10000–24999)
  ('emma.wagner@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'EmmaWagner',   'Emma',    'Wagner',   12000, 1500, 75),
  ('paul.becker@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'PaulBecker',   'Paul',    'Becker',   18500, 2000, 90),
  -- Diamant (25000+)
  ('sophie.lang@demo.de',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'SophieLang',   'Sophie',  'Lang',     28000, 2800, 110),
  ('max.vogel@demo.de',     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'MaxVogel',     'Max',     'Vogel',    35000, 3500, 130),
  ('lea.hoffmann@demo.de',  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LnuxYkz9Sza', 'LeaHoffmann',  'Lea',     'Hoffmann', 52000, 5000, 180)
ON CONFLICT (email) DO NOTHING;

-- Freundschaften mit Nutzer ID=1 (der echte Nutzer)
-- Angenommen, die Demo-Nutzer haben IDs 2-16 (falls ID=1 der erste echte Nutzer ist)
-- Wir nutzen Subqueries um sicher IDs zu holen
INSERT INTO friendships (user_id, friend_id, status)
SELECT u1.id, u2.id, 'ACCEPTED'
FROM users u1, users u2
WHERE u1.email = 'lena.braun@demo.de'  AND u2.email = 'tom.richter@demo.de'
ON CONFLICT DO NOTHING;

INSERT INTO friendships (user_id, friend_id, status)
SELECT u1.id, u2.id, 'ACCEPTED'
FROM users u1, users u2
WHERE u1.email = 'lena.braun@demo.de'  AND u2.email = 'sara.schulz@demo.de'
ON CONFLICT DO NOTHING;

INSERT INTO friendships (user_id, friend_id, status)
SELECT u1.id, u2.id, 'ACCEPTED'
FROM users u1, users u2
WHERE u1.email = 'felix.bauer@demo.de'  AND u2.email = 'jan.neumann@demo.de'
ON CONFLICT DO NOTHING;

INSERT INTO friendships (user_id, friend_id, status)
SELECT u1.id, u2.id, 'ACCEPTED'
FROM users u1, users u2
WHERE u1.email = 'nico.Fischer@demo.de'  AND u2.email = 'julia.weber@demo.de'
ON CONFLICT DO NOTHING;

INSERT INTO friendships (user_id, friend_id, status)
SELECT u1.id, u2.id, 'ACCEPTED'
FROM users u1, users u2
WHERE u1.email = 'emma.wagner@demo.de'  AND u2.email = 'sophie.lang@demo.de'
ON CONFLICT DO NOTHING;
