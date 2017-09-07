DROP TABLE cards;

CREATE TABLE cards
(
  uid SERIAL,
  name character varying, --
  manacost text[], --
  artist_id integer[],
  card_type_id integer[], --
  flavor_text character varying, --
  printings integer[],
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

--manacost
WITH substrings AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2)
FROM raw_card_data) 
SELECT string_to_array(substring, '}{') FROM substrings;


--artist_id  -- NEEDS WORK!
WITH substrings AS
(SELECT SUBSTRING(artist, 1)
FROM raw_card_data) 
SELECT string_to_array(substring, ' & ') FROM substrings;

WITH distinct_artists AS
(
SELECT DISTINCT regexp_split_to_table(raw_card_data.artist, E' & ') AS split_artists
FROM raw_card_data
)
SELECT split_artists FROM distinct_artists;


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
INNER JOIN subtypes t ON t.card_subtype = tr.split_types
WHERE split_types = card_subtype
GROUP BY uid
ORDER BY uid;



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
FROM raw_card_data) 
SELECT uid, 
	name, 
	string_to_array(manacost, '}{'), 
	array_agg(t.card_type_id ORDER BY card_type_id ASC), 
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
GROUP BY uid, name, manacost, flavor_text, type_flavor, layout_id, multiverse_id, power, toughness, rarity_id
ORDER BY uid;






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

CREATE TABLE formats
(
  format_id SERIAL,
  format_type character varying,
  valid_printings integer[]
);



CREATE TABLE cards_decks_xref
(
  deck_id integer,
  card_id integer,
  is_sidedeck boolean
);

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

INSERT INTO players(player_name, deck_id)
VALUES ('Mariah', ARRAY[1]);

INSERT INTO decks(deck_name)
VALUES ('DREDGE!');

select * from decks;
