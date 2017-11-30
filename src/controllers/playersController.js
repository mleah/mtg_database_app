const getAllPlayersSQL = `SELECT player_id, player_name FROM players`;

const getPlayerByIdSQL = `SELECT player_id, player_name FROM players WHERE player_id = $1`;

const addNewPlayerSQL = `
    INSERT INTO players (player_name) 
       VALUES ($1)`;

const updatePlayerNameSQL = `
    UPDATE players
    SET player_name = $1
    WHERE player_id = $2;
`;

const deletePlayerSQL = `
    DELETE FROM players
    WHERE player_id = $1;
`;

const getPlayersDecksSQL = `
    SELECT
        d.deck_name,
        d.deck_id
    FROM decks d
    INNER JOIN players_decks_xref pdx ON pdx.deck_id = d.deck_id
    INNER JOIN players p ON p.player_id = pdx.player_id
    WHERE p.player_id = $1;
`;

const addNewPlayerDeckSQL = `
    WITH deck_insert AS (
     INSERT INTO decks (deck_name)
        VALUES ($2)
        ON CONFLICT DO NOTHING
        RETURNING deck_id AS decks_deck_id
    ), cards_decks_xref_insert AS (
      INSERT INTO cards_decks_xref (deck_id, card_id)
      SELECT 
      di.decks_deck_id, 
      card_id
      FROM deck_insert di, unnest($3::int[]) card_id
    )
    INSERT INTO players_decks_xref(player_id, deck_id)
    SELECT
      $1,
      di.decks_deck_id
    FROM deck_insert di;    
`;

module.exports = {
    getAllPlayersSQL,
    getPlayerByIdSQL,
    addNewPlayerSQL,
    updatePlayerNameSQL,
    deletePlayerSQL,
    getPlayersDecksSQL,
    addNewPlayerDeckSQL
};