'use strict';

const Hapi = require('hapi');
const server = new Hapi.Server({ debug: { request: ['error'] } });
const hapiNodePostgres = require('hapi-node-postgres');
const databaseSecret = require('./secret.js');

server.connection({ port: 9001, host: 'localhost' });

const plugin = {
    register: hapiNodePostgres,
    options: {
        connectionString: databaseSecret,
        native: true
    }
};

server.register(plugin, (err) => {

    if (err) {
        console.error('Failed loading "hapi-node-postgres" plugin');
    }
});

server.route({
    method: 'GET',
    path: '/',
    handler: function (request, reply) {
        reply('Hello, world!');
    }
});

server.route({
    method: 'GET',
    path: '/cards',
    handler: function (request, reply) {
        const cardsQuery = `SELECT * FROM cards`;

        request.pg.client.query(cardsQuery, [], function(err, result) {
            reply({ 'cards' : result });

        });
    }
});

server.start((err) => {

    if (err) {
        throw err;
    }
    console.log(`Server running at: ${server.info.uri}`);
});