

--Get the players' decks


SELECT
    d.deck_name,
    d.deck_id
FROM decks d
INNER JOIN players_decks_xref pdx ON pdx.deck_id = d.deck_id
INNER JOIN players p ON p.player_id = pdx.player_id
WHERE p.player_id = 1;


--Add a deck for a player
WITH deck_insert AS (
 INSERT INTO decks (deck_name)
    VALUES ('deck TESTING')
    ON CONFLICT DO NOTHING
    RETURNING deck_id AS decks_deck_id
), cards_decks_xref_insert AS (
  INSERT INTO cards_decks_xref (deck_id, card_id)
    SELECT
      di.decks_deck_id,
      card_id
    FROM deck_insert di, unnest(ARRAY [1, 2, 3, 4, 5, 6, 7, 8]) card_id
)
INSERT INTO players_decks_xref(player_id, deck_id)
SELECT
  1,
  di.decks_deck_id
FROM deck_insert di;
