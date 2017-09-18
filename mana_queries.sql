
-- Some queries I kept coming back to

select * from players;

select manacost, name from cards_decks_xref cd
  INNER JOIN cards c ON c.uid = cd.card_id
WHERE deck_id = 1
AND is_sidedeck = 'f';

SELECT uid,
  name,
  array_length(manacost, 1),
  manacost
FROM cards;

--------------------------------------------------------------
-- I want to know the total mana cost of all cards in my deck
--------------------------------------------------------------


--First try, but this unnests the mana cost FOR EVERY SINGLE CARD
--Aggregate  (cost=102622.32..102622.33 rows=1 width=32) (actual time=63.888..63.888 rows=1 loops=1)
WITH split_mana AS
(
  SELECT
    unnest(manacost) AS raw_cost,
    uid
  FROM cards
)
SELECT
  SUM(CASE WHEN sm.raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	ELSE 1
	END) AS manacost
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
INNER JOIN cards_decks_xref cd ON c.uid = cd.card_id
INNER JOIN decks d ON d.deck_id = cd.deck_id
INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
  AND d.deck_name = 'TEST'  -- THis would be input/dynamic
  AND cd.is_sidedeck IS FALSE;  -- This could be adapted to be t/f/ or both


--This one is faster and costs way less, only unnests manacost for cards in the deck
--Aggregate  (cost=3021.16..3021.17 rows=1 width=32) (actual time=28.992..28.993 rows=1 loops=1)
WITH split_mana AS
(
  SELECT
    unnest(manacost) AS raw_cost
  FROM cards c
  INNER JOIN cards_decks_xref cd ON c.uid = cd.card_id
  INNER JOIN decks d ON d.deck_id = cd.deck_id
  INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
    WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
    AND d.deck_name = 'TEST'  -- THis would be input/dynamic
    AND cd.is_sidedeck IS FALSE  -- This could be adapted to be t/f/or both
)
SELECT
  SUM(CASE WHEN raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	ELSE 1
	END) AS manacost
FROM split_mana;


--------------------------------------------------------------
-- I want to know the CMC of each card I have in my deck
--------------------------------------------------------------


--This one returns every card that has a mana cost that is NOT NULL (including duplicate cards)
--Same issue as before, does EVERY card in the cards deck
--Hash Join  (cost=697936.45..777891.82 rows=5728 width=26) (actual time=109.176..201.366 rows=38 loops=1)

EXPLAIN ANALYZE WITH split_mana AS
(
  SELECT uid,
    SUM(CASE WHEN raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	  WHEN raw_cost ~ '[a-zA-Z]' THEN 1
	  END) AS total_manacost
    FROM
    ( SELECT
      unnest(manacost) AS raw_cost,
      uid AS uid
      FROM cards
    ) AS unnested_mana
  GROUP BY unnested_mana.uid
)
SELECT
  c.uid,  -- DISTINCT - do we want only one of each card returned?
  name,
  total_manacost AS cmc
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
INNER JOIN cards_decks_xref cd ON c.uid = cd.card_id
INNER JOIN decks d ON d.deck_id = cd.deck_id
INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
  AND d.deck_name = 'TEST'  -- THis would be input/dynamic
  AND cd.is_sidedeck IS FALSE; -- This could be adapted to be t/f/both



--This one returns every card that has a manacost or a manacost of NULL (including duplicate cards)
--Same issue as before, does EVERY card in the cards deck
--Hash Join  (cost=698020.61..777975.98 rows=5728 width=26) (actual time=88.692..152.907 rows=61 loops=1)

EXPLAIN ANALYZE WITH split_mana AS
(
  SELECT uid,
    SUM(CASE WHEN raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	  WHEN raw_cost ~ '[a-zA-Z]' THEN 1
	  END) AS total_manacost
    FROM
    ( SELECT
      uid AS uid,
      CASE WHEN array_length(manacost, 1) IS NOT NULL THEN unnest(manacost)
      END AS raw_cost
      FROM cards
    ) AS unnested_mana
  GROUP BY unnested_mana.uid
)
SELECT
  c.uid,  -- DISTINCT - do we want only one of each card returned?
  name,
  total_manacost AS cmc
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
INNER JOIN cards_decks_xref cd ON c.uid = cd.card_id
INNER JOIN decks d ON d.deck_id = cd.deck_id
INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
  AND d.deck_name = 'TEST'  -- THis would be input/dynamic
  AND cd.is_sidedeck IS FALSE; -- This could be adapted to be t/f/both


--Take TWO

--This one returns every card that has a mana cost that is NOT NULL (including duplicate cards)
-- ... this isn't working as expected  -___-

WITH individual_card_cmc AS
(
 SELECT uid,
      name,
    SUM(CASE WHEN raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	    WHEN raw_cost ~ '[a-zA-Z]' THEN 1
	    END) AS cmc
    FROM
    ( SELECT
        uid,
        unnest(manacost) AS raw_cost,
        name
      FROM cards c
      INNER JOIN cards_decks_xref cd ON c.uid = cd.card_id
      INNER JOIN decks d ON d.deck_id = cd.deck_id
      INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
      WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
        AND d.deck_name = 'TEST'  -- THis would be input/dynamic
        AND cd.is_sidedeck IS FALSE -- This could be adapted to be t/f/both
    ) AS unnested_mana
      GROUP BY unnested_mana.uid, unnested_mana.name
)
SELECT  ic.uid,
        ic.name,
        ic.cmc
  FROM individual_card_cmc ic
INNER JOIN cards_decks_xref cd ON ic.uid = cd.card_id
INNER JOIN decks d ON d.deck_id = cd.deck_id
INNER JOIN players p ON d.deck_id = ANY(p.deck_id)
  WHERE p.player_name = 'Mariah'  -- This would be input/dynamic
    AND d.deck_name = 'TEST'  -- THis would be input/dynamic
    AND cd.is_sidedeck IS FALSE -- This could be adapted to be t/f/both
GROUP BY ic.uid, ic.name, ic.cmc;


