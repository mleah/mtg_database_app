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
                        return {
                            printing_fullname: set.printing_fullname,
                            printing_abbr: set.printing_abbr,
                            cards: set.cards_array,
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
                        return {
                            printing_fullname: set.printing_fullname,
                            printing_abbr: set.printing_abbr,
                            cards: set.cards_array,
                        }
                    });
                    console.log(result);
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