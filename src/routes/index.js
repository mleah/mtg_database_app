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
        tags: ['api']
    }
});

server.route({
    method: 'GET',
    path: '/cards/{id}',
    config: {
        handler: function(request, reply) {
            let id = encodeURIComponent(request.params.id);

            request.pg.client.query(cards.cardsByIdSQL, [id], function(err, result) {
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
        tags: ['api'],
        validate: {
            params: {
                id : Joi.number()
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
        tags: ['api']
    }
});

server.route({
    method: 'GET',
    path: '/sets/{id}',
    config: {
        handler: function (request, reply) {
            let id = encodeURIComponent(request.params.id);

            request.pg.client.query(sets.setsByIdSQL, [id], function(err, result) {
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
        tags: ['api'],
        validate: {
            params: {
                id : Joi.number()
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
        tags: ['api'],
    }
});

//Will need to refactor later for when taking in a payload from the frontend
//Should eventually just be at the "players" endpoint
server.route({
    method: 'POST',
    path: '/players/{name}',
    config: {
        handler: function (request, reply) {
            let name = encodeURIComponent(request.params.name);

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
        tags: ['api'],
        validate: {
            params: {
                name : Joi.string()
                    .required()
                    .description('The name for the new player'),
            }
        }
    }
});


server.route({
    method: 'DELETE',
    path: '/players/{id}',
    config: {
        handler: function (request, reply) {
            let id = encodeURIComponent(request.params.id);

            request.pg.client.query(players.deletePlayerSQL, [id], function(err, result) {
                if(err) {
                    console.log(err);
                } else {
                    getAllPlayers(request, reply);
                }
            });
        },
        description: 'Delete a player by player_id',
        notes: 'Deletes a player by player_id and returns a list of all players',
        tags: ['api'],
        validate: {
            params: {
                id : Joi.number()
                    .required()
                    .description('The uid for the player'),
            }
        }
    }
});


//Will need to refactor later for when taking in a payload from the frontend
//Should eventually just be at the "players/id" endpoint
server.route({
    method: 'PUT',
    path: '/players/{id}/{name}',
    config: {
        handler: function (request, reply) {
            let name = encodeURIComponent(request.params.name);
            let id = encodeURIComponent(request.params.id);

            request.pg.client.query(players.updatePlayerNameSQL, [name, id], function(err, _) {
                if(err) {
                    console.log(err);
                } else {
                    getAllPlayers(request, reply);
                }
            });
        },
        description: 'Update an existing players name',
        notes: 'Updates an existing players name and returns a list of all players',
        tags: ['api'],
        validate: {
            params: {
                name : Joi.string()
                    .required()
                    .description('The name for the new player'),
                id : Joi.number()
                    .required()
                    .description('The uid for the player'),
            },
        }
    }
});