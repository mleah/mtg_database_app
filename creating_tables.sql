CREATE TABLE cards
(
  uid SERIAL,
  name character varying,
  manacost text[],
  artist_id integer[],
  card_type_id integer[],
  flavor_text character varying,
  printings integer[],
  type_flavor character varying,
  layout_id varchar[],
  multiverse_id integer,
  power character varying,
  toughness character varying,
  rarity_id integer,
  card_subtype_id integer[]
)


--RARITY
--6 rows

CREATE TABLE rarity
(
  rarity_id SERIAL,
  rarity_type character varying
)

INSERT INTO rarity(rarity_type)
SELECT DISTINCT rarity
FROM raw_card_data;


--TYPES
--12 rows

CREATE TABLE types
(
  card_type_id SERIAL,
  card_type character varying
)

INSERT INTO types(card_type)
WITH distinct_types AS
(
SELECT DISTINCT regexp_split_to_table(raw_card_data.types, E',') AS split_types
FROM raw_card_data
)
SELECT split_types FROM distinct_types;


--SUBTYPES
--321 rows

CREATE TABLE subtypes
(
  card_subtype_id SERIAL,
  card_subtype character varying
)

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
)

INSERT INTO layouts(layout_type)
SELECT DISTINCT layout
FROM raw_card_data;


--ARTISTS
--626 rows

CREATE TABLE artists
(
  artist_id SERIAL,
  artist_name character varying
)

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
)

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
)



CREATE TABLE cards_decks_xref
(
  deck_id integer,
  card_id integer,
  is_sidedeck boolean
)

CREATE TABLE decks
(
  deck_id SERIAL,
  deck_name varchar,
  format_id integer
)

CREATE TABLE players
(
  player_id SERIAL,
  player_name varchar,
  deck_id integer[]
)

INSERT INTO players(player_name, deck_id)
VALUES ('Mariah', ARRAY[1]);

INSERT INTO decks(deck_name)
VALUES ('DREDGE!');

select * from decks;
