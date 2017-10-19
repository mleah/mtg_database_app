const setsSQL = `
SELECT  array_agg( array[CAST(uid AS varchar), name] ) AS cards_array,
        p.printing_abbr AS printing_abbr,
        p.printing_fullname AS printing_fullname
  FROM (
    SELECT
      uid,
      name,
      unnest(printing_id) AS printings_unnested
    FROM cards
  ) AS cards_printings
INNER JOIN printings p ON p.printing_id = cards_printings.printings_unnested
GROUP BY p.printing_abbr, p.printing_fullname;`;


const setsByIdSQL = `
SELECT  array_agg( array[CAST(uid AS varchar), name] ) AS cards_array,
        p.printing_abbr AS printing_abbr,
        p.printing_fullname AS printing_fullname
  FROM (
    SELECT
      uid,
      name,
      unnest(printing_id) AS printings_unnested
    FROM cards
  ) AS cards_printings
INNER JOIN printings p ON p.printing_id = cards_printings.printings_unnested
    WHERE printing_id = $1
GROUP BY p.printing_abbr, p.printing_fullname`;

module.exports = {
    setsSQL,
    setsByIdSQL
};