select * from raw_card_data;

select * from cards;

select * from types;

SELECT unnest(manacost) AS raw_cost from cards;


--Find card based on if white

WITH split_mana AS
(
  SELECT
    unnest(manacost) AS raw_cost,
    uid
  FROM cards
)
SELECT c.uid,
      name,
      manacost
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
WHERE sm.raw_cost = 'W';


-- Find card based on if white of black and if a creature

WITH split_mana AS
(
  SELECT
    unnest(manacost) AS raw_cost,
    uid
  FROM cards
),
  split_types AS
(
  SELECT
    unnest(card_type_id) AS raw_type,
    uid
  FROM cards
)
SELECT c.uid,
      name,
      manacost,
      card_type
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
INNER JOIN split_types st ON st.uid = c.uid
INNER JOIN types t ON t.card_type_id = st.raw_type
WHERE sm.raw_cost IN ('W', 'B')
AND card_type = 'Creature';


WITH split_mana AS
(
  SELECT
    unnest(manacost) AS raw_cost,
    uid
  FROM cards
),
  split_types AS
(
  SELECT
    unnest(card_type_id) AS raw_type,
    uid
  FROM cards
)
SELECT c.uid,
      name,
      manacost,
      card_type
FROM cards c
INNER JOIN split_mana sm ON sm.uid = c.uid
INNER JOIN split_types st ON st.uid = c.uid
INNER JOIN types t ON t.card_type_id = st.raw_type
WHERE sm.raw_cost = 'W'
AND card_type = 'Creature';