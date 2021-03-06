const getAllDecksSQL = `
    SELECT
      d.deck_id,
      d.deck_name,
      array_agg(card_id) AS cards
    FROM decks d
      INNER JOIN cards_decks_xref cdx ON d.deck_id = cdx.deck_id
    GROUP BY d.deck_id, d.deck_name;
`;

const getDeckSQL = `
    SELECT
      d.deck_id,
      d.deck_name,
      array_agg(card_id) AS cards
    FROM decks d
      INNER JOIN cards_decks_xref cdx ON d.deck_id = cdx.deck_id
    WHERE d.deck_id = $1
    GROUP BY d.deck_id, d.deck_name;
`;

module.exports = {
    getAllDecksSQL,
    getDeckSQL
}