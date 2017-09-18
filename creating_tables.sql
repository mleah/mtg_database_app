DROP TABLE cards;

CREATE TABLE cards
(
  uid SERIAL,
  name character varying, --
  manacost text[], --
  artist_id integer[], --
  card_type_id integer[], --
  flavor_text character varying, --
  printing_id integer[],
  type_flavor character varying, --
  layout_id integer, --
  multiverse_id integer, --
  power character varying, --
  toughness character varying, --
  rarity_id integer, --
  card_subtype_id integer[]
);

select * from raw_card_data;

select * from cards;

select * from printings;

--manacost
WITH substrings AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2)
FROM raw_card_data) 
SELECT string_to_array(substring, '}{') FROM substrings;


--artist_id


--returns a column with the mapped artist_ids in an array
WITH artists_rcd AS
  (
      SELECT
        regexp_split_to_table(raw_card_data.artist, E' & ') AS split_artists,
        uid
      FROM raw_card_data
  )
  SELECT array_agg(artist_id
  ORDER BY artist_id ASC) AS artist_id,
    uid
  FROM artists_rcd tr
    INNER JOIN artists a ON a.artist_name = tr.split_artists
  WHERE split_artists = artist_name
  GROUP BY uid
  ORDER BY uid;


--used to update cards artist_id column if there is no artist_id column
WITH artist_mapping AS
(
  WITH artists_rcd AS
  (
      SELECT
        regexp_split_to_table(raw_card_data.artist, E' & ') AS split_artists,
        uid
      FROM raw_card_data
  )
  SELECT array_agg(artist_id
  ORDER BY artist_id ASC) AS artist_id,
    uid
  FROM artists_rcd tr
    INNER JOIN artists a ON a.artist_name = tr.split_artists
  WHERE split_artists = artist_name
  GROUP BY uid
  ORDER BY uid
)
UPDATE cards
  SET artist_id = artist_mapping.artist_id
FROM artist_mapping
WHERE cards.uid = artist_mapping.uid;



-- types  AS card_types_id []
WITH types_rcd AS
(
SELECT regexp_split_to_table(raw_card_data.types, E',') AS split_types,
uid
FROM raw_card_data
)
SELECT array_agg(card_type_id ORDER BY card_type_id ASC), uid 
FROM types_rcd tr
INNER JOIN types t ON t.card_type = tr.split_types
WHERE split_types = card_type
GROUP BY uid
ORDER BY uid;

--printings []


WITH printings_rcd AS
(
SELECT regexp_split_to_table(raw_card_data.printings, E',') AS split_printings,
uid
FROM raw_card_data
)
SELECT array_agg(printing_id ORDER BY printing_id ASC), uid
FROM printings_rcd pr
INNER JOIN printings p ON p.printing_abbr = pr.split_printings
GROUP BY uid
ORDER BY uid;



--layout_id 

SELECT layout_id from layouts l
INNER JOIN raw_card_data rcd ON l.layout_type = rcd.layout;



--rarity_id

SELECT rarity_id from rarity r
INNER JOIN raw_card_data rcd ON r.rarity_type = rcd.rarity;

select * from subtypes;



--subtype AS card_subtype_id []

WITH subtypes_rcd AS
(
SELECT regexp_split_to_table(raw_card_data.subtypes, E',') AS split_subtypes,
uid
FROM raw_card_data
)
SELECT array_agg(card_subtype_id ORDER BY card_subtype_id ASC), uid
FROM subtypes_rcd tr
INNER JOIN subtypes t ON t.card_subtype = tr.split_subtypes
WHERE split_subtypes = card_subtype
GROUP BY uid
ORDER BY uid;


WITH subtypes_mapping AS
(
  WITH subtypes_rcd AS
  (
    SELECT regexp_split_to_table(raw_card_data.subtypes, E',') AS split_subtypes,
    uid
    FROM raw_card_data
  )
  SELECT array_agg(card_subtype_id ORDER BY card_subtype_id ASC) as subtype_id, uid
  FROM subtypes_rcd tr
  INNER JOIN subtypes t ON t.card_subtype = tr.split_subtypes
  WHERE split_subtypes = card_subtype
  GROUP BY uid
  ORDER BY uid
)
UPDATE cards
  SET card_subtype_id = subtypes_mapping.subtype_id
FROM subtypes_mapping
WHERE cards.uid = subtypes_mapping.uid;




-- Bunch of gobbledygook
-- WITH subtypes_rcd AS
-- (
-- SELECT
--   CASE
--     WHEN subtypes IS NULL THEN NULL
--     ELSE regexp_split_to_table(raw_card_data.subtypes, E',')
--   END AS split_subtypes,
-- uid
-- FROM raw_card_data
-- )
-- SELECT uid, split_subtypes
-- FROM subtypes_rcd tr
--   WHERE NOT EXISTS (SELECT card_subtype FROM subtypes t WHERE t.card_subtype = tr.split_subtypes);
-- INNER JOIN subtypes t ON t.card_subtype = tr.split_subtypes
--    IS NOT DISTINCT FROM tr.split_subtypes
-- WHERE split_subtypes = card_subtype
-- GROUP BY uid
-- ORDER BY uid;

SELECT *
FROM tableA A
WHERE NOT EXISTS
(SELECT idx FROM tableB B WHERE B.idx = A.idx);



--There are some queries to start adding in data to the CARDS table

--First go around, only populate some values
INSERT INTO cards(uid, name, manacost, card_type_id, flavor_text, type_flavor, layout_id, multiverse_id, power, toughness, rarity_id)
WITH rcd_update AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2) AS manacost,
		regexp_split_to_table(raw_card_data.types, E',') AS split_types,
		uid, 
		name,
		text as flavor_text, 
		type AS type_flavor,
		layout,
		multiverseid AS multiverse_id, 
		power, 
		toughness,
		rarity
  FROM raw_card_data
)
SELECT rcd.uid,
	name, 
	string_to_array(manacost, '}{'),
	array_agg(t.card_type_id ORDER BY t.card_type_id ASC),
	flavor_text, 
	type_flavor, 
	layout_id, 
	multiverse_id, 
	power, 
	toughness, 
	rarity_id
FROM rcd_update rcd
INNER JOIN types t ON t.card_type = rcd.split_types
INNER JOIN rarity r ON r.rarity_type = rcd.rarity
INNER JOIN layouts l on l.layout_type = rcd.layout
GROUP BY rcd.uid, name, manacost, flavor_text, type_flavor, layout_id, multiverse_id, power, toughness, rarity_id
ORDER BY rcd.uid ASC;



-- This has problems with ordering by uid   ---- just kidding, so does the above
INSERT INTO cards(uid, name, manacost, artist_id, card_type_id, flavor_text, printing_id, type_flavor, layout_id, multiverse_id, power, toughness, rarity_id)
WITH rcd_update AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2) AS manacost,
		regexp_split_to_table(raw_card_data.types, E',') AS split_types,
		uid,
		name,
		text as flavor_text,
		type AS type_flavor,
		layout,
		multiverseid AS multiverse_id,
		power,
		toughness,
		rarity
FROM raw_card_data),
artists_split AS
( WITH artists_rcd AS
    (
      SELECT regexp_split_to_table(raw_card_data.artist, E' & ') AS split_artists,
      uid
      FROM raw_card_data
    )
  SELECT array_agg(artist_id ORDER BY artist_id ASC) AS artist_id,
    uid
  FROM artists_rcd tr
  INNER JOIN artists a ON a.artist_name = tr.split_artists
  WHERE split_artists = artist_name
  GROUP BY uid
),
printings_split AS
( WITH printings_rcd AS
    (
    SELECT regexp_split_to_table(raw_card_data.printings, E',') AS split_printings,
    uid
    FROM raw_card_data
    )
  SELECT array_agg(printing_id ORDER BY printing_id ASC) AS printing_id, uid
  FROM printings_rcd pr
  INNER JOIN printings p ON p.printing_abbr = pr.split_printings
  GROUP BY uid
  ORDER BY uid
)
SELECT rcd.uid,
	name,
	string_to_array(manacost, '}{'),
  artist_id,
	array_agg(t.card_type_id ORDER BY t.card_type_id ASC),
	flavor_text,
  printing_id,
	type_flavor,
	layout_id,
	multiverse_id,
	power,
	toughness,
	rarity_id
FROM rcd_update rcd
INNER JOIN types t ON t.card_type = rcd.split_types
INNER JOIN rarity r ON r.rarity_type = rcd.rarity
INNER JOIN layouts l on l.layout_type = rcd.layout
INNER JOIN artists_split a ON a.uid = rcd.uid
INNER JOIN printings_split p ON p.uid = rcd.uid
GROUP BY rcd.uid, name, manacost, artist_id, flavor_text, printing_id, type_flavor, layout_id, multiverse_id, power, toughness, rarity_id
ORDER BY rcd.uid;






--RARITY
--6 rows

CREATE TABLE rarity
(
  rarity_id SERIAL,
  rarity_type character varying
);

INSERT INTO rarity(rarity_type)
SELECT DISTINCT rarity
FROM raw_card_data;


--TYPES
--12 rows

CREATE TABLE types
(
  card_type_id SERIAL,
  card_type character varying
);

INSERT INTO types(card_type)
WITH distinct_types AS
(
SELECT regexp_split_to_table(raw_card_data.types, E',') AS split_types
FROM raw_card_data
)
SELECT split_types FROM distinct_types;


--SUBTYPES
--321 rows

CREATE TABLE subtypes
(
  card_subtype_id SERIAL,
  card_subtype character varying
);

INSERT INTO subtypes(card_subtype)
WITH distinct_types AS
(
SELECT DISTINCT regexp_split_to_table(raw_card_data.subtypes, E',') AS split_subtypes
FROM raw_card_data
)
SELECT split_subtypes FROM distinct_types;


--LAYOUTS
--12 rows

CREATE TABLE layouts
(
  layout_id SERIAL,
  layout_type character varying
);

INSERT INTO layouts(layout_type)
SELECT DISTINCT layout
FROM raw_card_data;


--ARTISTS
--626 rows

CREATE TABLE artists
(
  artist_id SERIAL,
  artist_name character varying
);

INSERT INTO artists(artist_name)
WITH distinct_artists AS
(
SELECT DISTINCT regexp_split_to_table(raw_card_data.artist, E' & ') AS split_artists
FROM raw_card_data
)
SELECT split_artists FROM distinct_artists;


--PRITINGS
-- 210 rows

CREATE TABLE printings
(
  printing_id SERIAL,
  printing_abbr character varying,
  printing_fullname character varying
);

INSERT INTO printings(printing_abbr)
WITH distinct_printings AS
(
SELECT DISTINCT regexp_split_to_table(raw_card_data.printings, E',') AS split_printings
FROM raw_card_data
)
SELECT split_printings FROM distinct_printings;


--FORMATS

CREATE TABLE formats
(
  format_id SERIAL,
  format_type character varying,
  valid_printings integer[]
);


--CARD AND DECK CROSS REFERENCE

CREATE TABLE cards_decks_xref
(
  deck_id integer,
  card_id integer,
  is_sidedeck boolean
);

--DECK TABLE

CREATE TABLE decks
(
  deck_id SERIAL,
  deck_name varchar,
  format_id integer
);

CREATE TABLE players
(
  player_id SERIAL,
  player_name varchar,
  deck_id integer[]
);

--ADD IN SOME TESTING VALUES FOR NOW

INSERT INTO players(player_name, deck_id)
VALUES ('Mariah', ARRAY[1]);

INSERT INTO decks(deck_name)
VALUES ('DREDGE!');






-- ARRAY TESTING


select * from raw_card_data;

select * from cards;





























