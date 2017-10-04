
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

WITH artists AS (
  SELECT uid,
    string_agg(a.artist_name, ' & ') AS artist_name
    FROM (
      SELECT
      uid,
      unnest(artist_id) AS artist_id_unnested
      FROM cards
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
      WHERE uid = 1
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


