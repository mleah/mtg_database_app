const getAllPlayersSQL = `SELECT player_id, player_name FROM players`;

const getPlayerByIdSQL = `SELECT player_id, player_name FROM players`;

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

module.exports = {
    getAllPlayersSQL,
    getPlayerByIdSQL,
    addNewPlayerSQL,
    updatePlayerNameSQL,
    deletePlayerSQL
};