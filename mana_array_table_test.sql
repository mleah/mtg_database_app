select manacost from raw_card_data;

select string_to_array(manacost, '}{')
from raw_card_data;

WITH substrings AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2)
FROM raw_card_data) 
SELECT string_to_array(substring, '}{') FROM substrings;

DROP table testing_mana;

CREATE TABLE testing_mana
( 
uid integer,
name varchar,
manacost text[],
type varchar,
power character varying,
 toughness character varying
 )


WITH substrings AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2)
FROM raw_card_data) 
SELECT string_to_array(substring, '}{') FROM substrings;


INSERT INTO testing_mana(uid, name, type, power, toughness)
SELECT uid, name, type, power, toughness FROM raw_card_data;


--THIS DID IT YAY
INSERT INTO testing_mana(uid, name, manacost, type, power, toughness)
WITH substrings AS
(SELECT SUBSTRING(manacost, 2, LENGTH(manacost)-2) AS manacost, uid, name, type, power, toughness
FROM raw_card_data) 
SELECT uid, name, string_to_array(manacost, '}{'), type, power, toughness FROM substrings;

select * from testing_mana;

SELECT *
FROM testing_mana
WHERE '2/B' = ANY(manacost);

SELECT *
FROM testing_mana
WHERE '1' = ANY(manacost);

--IS CONTAINED BY - Contains Black,Green,White,AND blUe mana
SELECT *
FROM testing_mana
WHERE ARRAY['B', 'G', 'W', 'U'] <@ manacost;

--OVERLAP - Contains Black,Green,White,OR blUe mana
SELECT *
FROM testing_mana
WHERE '{B, G, W, U}' && manacost;

-- Checking for ANY uncolored mana is a bit different - can't use 0-9 as a set because it's a string here... 
SELECT *
FROM testing_mana
WHERE manacost && '{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}';


SELECT v AS value_repeated,array_agg(uid) AS is_repeated_on FROM 
(select uid,unnest(manacost) as v from testing_mana) AS test
GROUP by test.v HAVING Count(Distinct test.uid) > 1;

--"0"
--"1"
--"10"
--"11"
--"12"
--"15"
--"16"
--"2"
--"2/B"
--"2/G"
--"2/R"
--"2/U"
--"2/W"
--"3"
--"4"
--"5"
--"6"
--"7"
--"8"
--"9"
--"B"
--"B/G"
--"B/P"
--"B/R"
--"C"
--"G"
--"G/P"
--"G/U"
--"G/W"
--"R"
--"R/G"
--"R/P"
--"R/W"
--"U"
--"U/B"
--"U/P"
--"U/R"
--"W"
--"W/B"
--"W/P"
--"W/U"
--"X"


select * FROM testing_mana;

SELECT CASE WHEN CAST(raw_cost AS integer) < 10 THEN CAST(raw_cost AS integer)
	ELSE 1 
	END AS COST
FROM (SELECT unnest(manacost) AS raw_cost from testing_mana) AS a;

-- Casting characters as integers?  Is there a way to reject characters?  Can you check type of a thing?


SELECT CASE WHEN raw_cost ~ '^[0-9]+$' THEN CAST(raw_cost AS integer)
	ELSE 1 
	END AS COST
FROM (SELECT unnest(manacost) AS raw_cost from testing_mana) AS a
ORDER BY cost DESC;

SELECT pg_typeof(raw_cost), raw_cost
FROM (SELECT unnest(manacost) AS raw_cost from testing_mana) AS a;