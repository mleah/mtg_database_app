
select * from cards;

select * from raw_card_data;

-- cmc
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





--ALL CARDS
--Merge Join  (cost=10769533.10..27243354015763045285888.00 rows=10897341523897976958746624 width=281) (actual time=881.308..979.224 rows=20305 loops=1)

WITH unnested_cards AS (
  SELECT DISTINCT uid,
    string_agg(DISTINCT t.card_type, ',') AS card_type,
    string_agg(DISTINCT a.artist_name, ' & ') AS artist_name,
    string_agg(DISTINCT p.printing_abbr, ',') AS printing,
    FROM (
      SELECT
      uid,
      unnest(card_type_id) AS card_type_unnested,
      unnest(artist_id) AS artist_id_unnested,
      unnest(printing_id) AS printings_unnested,
      unnest(card_subtype_id) AS card_subtype_unnested
      FROM cards
    ) AS cards_unnested
  INNER JOIN types t ON t.card_type_id = cards_unnested.card_type_unnested
  INNER JOIN artists a ON a.artist_id = cards_unnested.artist_id_unnested
  INNER JOIN printings p ON p.printing_id = cards_unnested.printings_unnested
  INNER JOIN subtypes st ON st.card_subtype_id = cards_unnested.card_subtype_unnested
  GROUP BY cards_unnested.uid
),
converted_manacost AS (
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
SELECT c.uid,
  name,
  array_to_string(manacost, ',') AS manacost,
  cm.total_manacost AS cmc,
  uc.artist_name AS artist,
  uc.card_type AS card_type,
  uc.printing AS printing,
  type_flavor,
  l.layout_type AS layout,
  multiverse_id,
  power,
  toughness,
  r.rarity_type AS rarity,
  uc.card_subtype AS card_subtype
FROM cards c
  INNER JOIN unnested_cards uc ON uc.uid = c.uid
INNER JOIN layouts l ON l.layout_id = c.layout_id
INNER JOIN rarity r ON r.rarity_id = c.rarity_id
INNER JOIN converted_manacost cm ON cm.uid = c.uid
ORDER BY c.uid;




-- BY UID
-- Hash Join  (cost=14795.51..17774.64 rows=38 width=281) (actual time=57.991..61.153 rows=1 loops=1)

WITH artists AS (
  SELECT uid,
    string_agg(a.artist_name, ' & ') AS artist_name
    FROM (
      SELECT
      uid,
      unnest(artist_id) AS artist_id_unnested
      FROM cards
      WHERE uid = 1
    ) AS cards_artists
  INNER JOIN artists a ON a.artist_id = cards_artists.artist_id_unnested
  GROUP BY cards_artists.uid
),
card_types AS (
  SELECT uid,
    string_agg(t.card_type, ',') AS card_type
    FROM (
      SELECT
      uid,
      unnest(card_type_id) AS card_type_unnested
      FROM cards
      WHERE uid = 1
    ) AS cards_types
  INNER JOIN types t ON t.card_type_id = cards_types.card_type_unnested
  GROUP BY cards_types.uid
),
printings AS (
  SELECT uid,
    string_agg(p.printing_abbr, ',') AS printing
    FROM (
      SELECT
      uid,
      unnest(printing_id) AS printings_unnested
      FROM cards
      WHERE uid = 1
    ) AS cards_printings
  INNER JOIN printings p ON p.printing_id = cards_printings.printings_unnested
  GROUP BY cards_printings.uid
),
card_subtypes AS (
  SELECT uid,
    string_agg(st.card_subtype, ',') AS card_subtype
    FROM (
      SELECT
      uid,
      unnest(card_subtype_id) AS card_subtype_unnested
      FROM cards
      WHERE uid = 1
    ) AS cards_subtypes
  INNER JOIN subtypes st ON st.card_subtype_id = cards_subtypes.card_subtype_unnested
  GROUP BY cards_subtypes.uid
),
converted_manacost AS (
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
      WHERE uid = 347
    ) AS unnested_mana
  GROUP BY unnested_mana.uid
)
SELECT c.uid,
  name,
  array_to_string(manacost, ',') AS manacost,
  cm.total_manacost AS cmc,
  a.artist_name AS artist,
  ct.card_type AS card_type,
  p.printing AS printing,
  type_flavor,
  l.layout_type AS layout,
  multiverse_id,
  power,
  toughness,
  r.rarity_type AS rarity,
  st.card_subtype AS card_subtype
FROM cards c
INNER JOIN artists a ON a.uid = c.uid
INNER JOIN card_types ct ON ct.uid = c.uid
INNER JOIN printings p ON p.uid = c.uid
INNER JOIN layouts l ON l.layout_id = c.layout_id
INNER JOIN rarity r ON r.rarity_id = c.rarity_id
INNER JOIN card_subtypes st ON st.uid = c.uid
INNER JOIN converted_manacost cm ON cm.uid = c.uid
WHERE c.uid = 1;


SELECT DISTINCT uid,
    string_agg(DISTINCT t.card_type, ',') AS card_type,
    string_agg(DISTINCT a.artist_name, ' & ') AS artist_name,
    string_agg(DISTINCT p.printing_abbr, ',') AS printing,
    string_agg(DISTINCT st.card_subtype, ',') AS card_subtype
    FROM (
      SELECT
      uid,
      unnest(card_type_id) AS card_type_unnested,
      unnest(artist_id) AS artist_id_unnested,
      unnest(printing_id) AS printings_unnested,
      unnest(card_subtype_id) AS card_subtype_unnested
      FROM cards
    ) AS cards_unnested
  INNER JOIN types t ON t.card_type_id = cards_unnested.card_type_unnested
  INNER JOIN artists a ON a.artist_id = cards_unnested.artist_id_unnested
  INNER JOIN printings p ON p.printing_id = cards_unnested.printings_unnested
  INNER JOIN subtypes st ON st.card_subtype_id = cards_unnested.card_subtype_unnested
  GROUP BY cards_unnested.uid;


SELECT uid,
    string_agg(DISTINCT st.card_subtype, ',') AS card_subtype
    FROM (
      SELECT
      uid,
      CASE WHEN array_length(card_subtype_id, 1) IS NOT NULL THEN unnest(card_subtype_id)
        END AS card_subtype_unnested
      FROM cards
      ORDER BY uid
    ) AS cards_subtypes
  INNER JOIN subtypes st ON st.card_subtype_id = cards_subtypes.card_subtype_unnested
  GROUP BY cards_subtypes.uid;


-- UPDATED QUERY
--Merge Join  (cost=9553662.28..5927920255.13 rows=2284939427920 width=281) (actual time=2534.307..2580.280 rows=20305 loops=1)
-- AFTER PRIMARY KEYS on all tables  Merge Join  (cost=1433561.15..11038142.81 rows=3683321315 width=281) (actual time=2518.809..2565.087 rows=20305 loops=1)
EXPLAIN ANALYZE WITH unnested_cards AS (
  SELECT DISTINCT uid,
    string_agg(DISTINCT t.card_type, ',') AS card_type,
    string_agg(DISTINCT a.artist_name, ' & ') AS artist_name,
    string_agg(DISTINCT p.printing_abbr, ',') AS printing,
    string_agg(DISTINCT st.card_subtype, ',') AS card_subtype
    FROM (
      SELECT
      uid,
      unnest(card_type_id) AS card_type_unnested,
      unnest(artist_id) AS artist_id_unnested,
      unnest(printing_id) AS printings_unnested,
      unnest(card_subtype_id) AS card_subtype_unnested
      FROM cards
    ) AS cards_unnested
  INNER JOIN types t ON t.card_type_id = cards_unnested.card_type_unnested
  INNER JOIN artists a ON a.artist_id = cards_unnested.artist_id_unnested
  INNER JOIN printings p ON p.printing_id = cards_unnested.printings_unnested
  INNER JOIN subtypes st ON st.card_subtype_id = cards_unnested.card_subtype_unnested
  GROUP BY cards_unnested.uid
),
converted_manacost AS (
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
SELECT c.uid,
  name,
  array_to_string(manacost, ',') AS manacost,
  cm.total_manacost AS cmc,
  uc.artist_name AS artist,
  uc.card_type AS card_type,
  uc.printing AS printing,
  type_flavor,
  l.layout_type AS layout,
  multiverse_id,
  power,
  toughness,
  r.rarity_type AS rarity,
  uc.card_subtype AS card_subtype
FROM cards c
  INNER JOIN unnested_cards uc ON uc.uid = c.uid
INNER JOIN layouts l ON l.layout_id = c.layout_id
INNER JOIN rarity r ON r.rarity_id = c.rarity_id
INNER JOIN converted_manacost cm ON cm.uid = c.uid
ORDER BY c.uid;