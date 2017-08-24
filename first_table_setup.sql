COPY raw_card_data(name,manaCost,cmc,colorIdentity,artist,number,type,text,printings,flavor,layout,multiverseid,power,toughness,rarity,subtypes,types) 
FROM 'path_to_file/mtg_cards.csv' DELIMITER ',' CSV;

--DROP TABLE raw_card_data

CREATE TABLE raw_card_data
(
uid serial,
name varchar,
manaCost varchar,
cmc varchar, -- should this be NUMERIC(3, 1) instead???
colorIdentity varchar,
artist varchar,
number varchar,
type varchar,
text varchar,
printings varchar,
flavor varchar,
layout varchar,
multiverseid integer,
power varchar,
toughness varchar,
rarity varchar,
subtypes varchar,
types varchar
)

select * from raw_card_data