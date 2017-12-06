'use strict';

const Hapi = require('hapi');
const Joi = require('joi');
const Inert = require('inert');
const Vision = require('vision');
const HapiSwagger = require('hapi-swagger');
const HapiNodePostgres = require('hapi-node-postgres');
const server = new Hapi.Server();
const databaseSecret  = require('./secret.js');
const cards = require("../controllers/cardsController.js");
const sets = require("../controllers/setsController.js");
const players = require("../controllers/playersController");
const decks = require("../controllers/decksController");

server.connection({ port: 9001, host: 'localhost' });

const options = {
    info: {
        'title': 'MTG API Documentation',
        'version': "1.0.0",
    }
};

server.register([
    Inert,
    Vision,
    {
        'register': HapiSwagger,
        'options': options
    },
    {
        register: HapiNodePostgres,
        options: {
            connectionString: databaseSecret,
            native: true
        }
    }
], () => {
    server.start( (err) => {
        if (err) {
            console.log(err);
        } else {
            console.log('Server running at:', server.info.uri);
        }
    });
});

server.route({
    method: 'GET',
    path: '/cards',
    config: {
        handler: function (request, reply) {
            request.pg.client.query(cards.cardsSQL, [], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const cards = result.rows.map( (card) => card);
                    reply({ 'cards' : cards });
                }
            });
        },
        description: 'Get all cards',
        notes: 'Returns the list of all cards and their information',
        tags: ['api', 'cards']
    }
});

server.route({
    method: 'GET',
    path: '/cards/{card_id}',
    config: {
        handler: function(request, reply) {
            let cardID = encodeURIComponent(request.params.card_id);

            request.pg.client.query(cards.cardsByIdSQL, [cardID], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const cards = result.rows.map( (card) => card);
                    reply({ 'cards' : cards });
                }

            });
        },
        description: 'Get a card by uid',
        notes: 'Returns a single card from the supplied uid',
        tags: ['api', 'cards'],
        validate: {
            params: {
                card_id : Joi.number()
                    .required()
                    .description('the uid for card'),
            }
        }
    }
});

server.route({
    method: 'GET',
    path: '/sets',
    config: {
        handler: function (request, reply) {
            request.pg.client.query(sets.setsSQL, [], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const sets = result.rows.map( (set) => {
                        const cardObject = set.cards_array.map( (card) => {
                           return {
                               id: card[0],
                               card_name: card[1],
                           }
                        });
                        return {
                            printing_fullname: set.printing_fullname,
                            printing_abbr: set.printing_abbr,
                            cards: cardObject,
                        }
                    });
                    reply({ 'sets' : sets });
                }
            });
        },
        description: 'Get all sets',
        notes: 'Returns the list of all sets and their information and the cards within each set',
        tags: ['api', 'sets']
    }
});

server.route({
    method: 'GET',
    path: '/sets/{set_id}',
    config: {
        handler: function (request, reply) {
            let setID = encodeURIComponent(request.params.set_id);

            request.pg.client.query(sets.setsByIdSQL, [setID], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const sets = result.rows.map( (set) => {
                        const cardObject = set.cards_array.map( (card) => {
                            return {
                                id: card[0],
                                card_name: card[1],
                            }
                        });
                        return {
                            printing_fullname: set.printing_fullname,
                            printing_abbr: set.printing_abbr,
                            cards: cardObject,
                        }
                    });
                    reply({ 'sets' : sets });
                }
            });
        },
        description: 'Get a set by uid',
        notes: 'Returns a single set and all cards in the set based on the set uid',
        tags: ['api', 'sets'],
        validate: {
            params: {
                set_id : Joi.number()
                    .required()
                    .description('the uid for set'),
            }
        }
    }
});

const getAllPlayers = (request, reply) => {
    request.pg.client.query(players.getAllPlayersSQL, [], function(err, result) {
        if(err) {
            console.log(err);
        } else {
            const player = result.rows.map( (player) => {
                return {
                    player_name: player.player_name,
                    player_id: player.player_id
                }
            });
            reply({ 'players' : player });
        }
    });
}

server.route({
    method: 'GET',
    path: '/players',
    config: {
        handler: getAllPlayers,
        description: 'Get all players',
        notes: 'Returns all players',
        tags: ['api', 'players'],
    }
});

//Will need to refactor later for when taking in a payload from the frontend
server.route({
    method: 'POST',
    path: '/players',
    config: {
        handler: function (request, reply) {
            let name = encodeURIComponent(request.payload.name);

            request.pg.client.query(players.addNewPlayerSQL, [name], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getAllPlayers(request, reply);
                }
            });
        },
        description: 'Create a new player',
        notes: 'Creates a new player and then returns all player information',
        tags: ['api', 'players'],
        validate: {
            payload: Joi.object({
                name : Joi.string()
                    .required()
                    .description('The name for the new player'),
            })
        }
    }
});

server.route({
    method: 'GET',
    path: '/players/{player_id}',
    config: {
        handler: function (request, reply) {
            const playerID = encodeURIComponent(request.params.player_id);

            request.pg.client.query(players.getPlayerByIdSQL, [playerID], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const player = result.rows.map( (player) => {
                        return {
                            player_name: player.player_name,
                            player_id: player.player_id
                        }
                    });
                    reply({ 'players' : player });
                }
            });
        },
        description: 'Get a player by id',
        notes: 'Returns the player',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                player_id : Joi.number()
                    .required()
                    .description('The uid for the player'),
            })
        }
    }
});

server.route({
    method: 'DELETE',
    path: '/players/{player_id}',
    config: {
        handler: function (request, reply) {
            const playerID = encodeURIComponent(request.params.player_id);

            request.pg.client.query(players.deletePlayerSQL, [playerID], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getAllPlayers(request, reply);
                }
            });
        },
        description: 'Delete a player by player_id',
        notes: 'Deletes a player by player_id and returns a list of all players',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                player_id : Joi.number()
                    .required()
                    .description('The uid for the player'),
            })
        }
    }
});


//Will need to refactor later for when taking in a payload from the frontend
server.route({
    method: 'PUT',
    path: '/players/{player_id}',
    config: {
        handler: function (request, reply) {
            const name = encodeURIComponent(request.payload.name);
            const playerID = encodeURIComponent(request.params.player_id);

            request.pg.client.query(players.updatePlayerNameSQL, [name, playerID], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getAllPlayers(request, reply);
                }
            });
        },
        description: 'Update an existing players name',
        notes: 'Updates an existing players name and returns a list of all players',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                player_id: Joi.number()
                    .required()
                    .description('The uid for the player')
            }),
            payload: Joi.object({
                name : Joi.string()
                    .required()
                    .description('The name for the new player'),
            })
        }
    }
});

const getPlayersDecks = (request, reply) => {
    const playerID = encodeURIComponent(request.params.player_id);

    request.pg.client.query(players.getPlayersDecksSQL, [playerID], function(err, result) {
        if(err) {
            console.log(err);
        } else {
            const decks = result.rows.map( (deck) => {
                return {
                    deck_name: deck.deck_name,
                    deck_id: deck.deck_id
                }
            });
            reply({ 'decks' : decks });
        }
    });
};

server.route({
    method: 'GET',
    path: '/players/{player_id}/deck',
    config: {
        handler: getPlayersDecks,
        description: 'Get all decks associated with a single player',
        notes: 'Returns a list of decks associated with a single player by player id',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                id: Joi.number()
                    .required()
                    .description('The uid for the player')
            }),
        }
    }
});

server.route({
    method: 'POST',
    path: '/players/{player_id}/deck',
    config: {
        handler: function (request, reply) {

            // Need to handle the escaped characters for the deckName....
            const playerID = encodeURIComponent(request.params.player_id);
            const deckName = encodeURIComponent(request.payload.deckName);
            const cardIDs = request.payload.card_ids;

            console.log('cardIds for POST,',  cardIDs);

            request.pg.client.query(players.addNewPlayerDeckSQL, [playerID, deckName, cardIDs], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getPlayersDecks(request, reply);
                }
            });
        },
        description: 'Create a new deck for a single player',
        notes: 'Creates a new deck for a single player by player_id',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                player_id: Joi.number()
                    .required()
                    .description('The uid for the player')
            }),
            payload: Joi.object({
                deckName : Joi.string()
                    .required()
                    .description('The name for the new deck'),
                card_ids : Joi.array()
                    .description('An array of card ids in the deck')
            })
        }
    }
});

//should this take all new card ids and just remove the old cards and insert the new ones?

server.route({
    method: 'PUT',
    path: '/players/{player_id}/deck/{deck_id}',
    config: {
        handler: function (request, reply) {
            const playerID = encodeURIComponent(request.params.player_id);
            const deckID = encodeURIComponent(request.params.deck_id);
            const deckName = encodeURIComponent(request.payload.deckName);
            const cardIDs = request.payload.card_ids;

            request.pg.client.query(players.updatePlayerDeckSQL, [playerID, deckID, deckName, cardIDs], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getPlayersDecks(request, reply);
                }
            });
        },
        description: 'Update a deck for a single player',
        notes: 'Creates a new deck for a single player by id',
        tags: ['api', 'players'],
        validate: {
            params: Joi.object({
                player_id: Joi.number()
                    .required()
                    .description('The uid for the player'),
                deck_id: Joi.number()
                    .required()
                    .description('THe uid for the deck')
            }),
            payload: Joi.object({
                deckName : Joi.string()
                    .description('The updated name for the deck'),
                card_ids : Joi.array()
                    .description('An array of card ids in the deck')
            })
        }
    }
});

server.route({
    method: 'DELETE',
    path: '/players/{player_id}/deck/{deck_id}',
    config: {
        handler: function (request, reply) {
            const playerID = encodeURIComponent(request.params.player_id);
            const deckID = encodeURIComponent(request.params.deck_id);

            request.pg.client.query(players.deletePlayerDeckSQL, [playerID, deckID], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getPlayersDecks(request, reply);
                }
            });
        },
        description: 'Delete a deck for a player',
        notes: 'Deletes a deck for a single player by id',
        tags: ['api','players'],
        validate: {
            params: Joi.object({
                player_id: Joi.number()
                    .required()
                    .description('The uid for the player'),
                deck_id:  Joi.number()
                    .required()
                    .description('The uid for the deck'),
            })
        }
    }
});


server.route({
    method: 'GET',
    path: '/decks',
    config: {
        handler: function (request, reply) {
            request.pg.client.query(decks.getAllDecksSQL, [], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const decks = result.rows.map( (deck) => {
                        return {
                            deck_name: deck.deck_name,
                            deck_id: deck.deck_id,
                            cards: deck.cards
                        }
                    });
                    reply({ 'decks' : decks });
                }
            });
        },
        description: 'Get all decks',
        notes: 'Returns all decks with the card_ids for all their cards',
        tags: ['api', 'decks']
    }
});


server.route({
    method: 'GET',
    path: '/decks/{deck_id}',
    config: {
        handler: function (request, reply) {
            const deck_id = encodeURIComponent(request.params.deck_id);
            request.pg.client.query(decks.getDeckSQL, [deck_id], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    const deck = result.rows.map( (deck) => {
                        return {
                            deck_name: deck.deck_name,
                            deck_id: deck.deck_id,
                            cards: deck.cards
                        }
                    });
                    reply({ 'deck' : deck });
                }
            });
        },
        description: 'Get a deck by deck_id',
        notes: 'Returns the deck and includes the card_ids for all cards',
        tags: ['api', 'decks'],
        validate: {
            params: Joi.object({
                deck_id:  Joi.number()
                    .required()
                    .description('The uid for the deck'),
            })
        }
    }
});
