-- =============================================================
-- v3: Shop-Item Fix + displayName Index
-- =============================================================

-- Münzregen (COIN_BOOST) umbenannt in XP-Schub – gibt jetzt 200 XP statt 50 Münzen
-- (Münzen gegen Münzen kaufen ergibt keinen Sinn)
UPDATE items
SET name        = 'XP-Schub',
    description = 'Gibt dir sofort 200 XP'
WHERE item_type = 'COIN_BOOST';
