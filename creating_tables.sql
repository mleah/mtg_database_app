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

CREATE TABLE rarity
(
  uid SERIAL,
  rarity_type character varying
)

CREATE TABLE types
(
  uid SERIAL,
  card_type character varying
)

CREATE TABLE subtypes
(
  uid SERIAL,
  card_subtype character varying
)

CREATE TABLE layouts
(
  uid SERIAL,
  layout_type character varying
)

CREATE TABLE artists
(
  uid SERIAL,
  artist_name character varying
)

CREATE TABLE printings
(
  uid SERIAL,
  printing_abbr character varying,
  printing_fullname character varying
)

CREATE TABLE printings
(
  uid SERIAL,
  printing_abbr character varying,
  printing_fullname character varying
)