Keratin AuthN is an authentication service that keeps you in control of the experience without forcing you to be an expert in web security.

Read more at [keratin.tech](https://keratin.tech).

[![Build Status](https://travis-ci.org/keratin/authn.svg?branch=master)](https://travis-ci.org/keratin/authn)

# Integration

This repository contains a Ruby on Rails API service. Your application is expected to host and manage any frontend (client) code as well as deliver any appropriate emails. In some cases this means creating an endpoint with which AuthN can coordinate.

You will need to integrate client libraries for your application's backend ([Ruby](https://github.com/keratin/authn-rb)) and frontend ([JavaScript](https://github.com/keratin/authn-js)). If you need a new client library, please [submit a request](https://github.com/keratin/authn/issues).

## Example: Signup

You will render a signup form as usual, but rely on a provided client library to register the username and password with AuthN in exchange for an ID Token (aka JWT session) that is submitted to your user signup endpoint instead.

    Your Frontend      AuthN       Your Backend
    ===========================================
                 <---------------- signup form

    Email &
    Password     ----> account signup
                 <---- ID Token

    Name &
    Email &
    ID Token     ----------------> user signup

## Example: Password Reset

You will render a reset form as usual, but then submit the username to AuthN. If that username exists, AuthN will communicate a secret token to your application through a secure back channel. Your application is responsible for delivering the token to the user, probably by email.

Your application must then host a form that embeds the token, requests a new password, and submits to AuthN for processing.

    Your Frontend      AuthN       Your Backend
    ===========================================
    Username     ---->
                       account_id &
                       token ---->
                 <---------------- emailed token

                 <---------------- reset form
    Password &
    Token        ----> update

# Deployment

AuthN may be deployed according to your needs. Here's what it requires:

* A Redis server for session tokens, ephemeral data, and activity metrics.
* A SQL server with ActiveRecord ORM support, like MySQL, PostgreSQL, or SQL Server.
* Network routing from your application's clients.
* Network routing to/from your application, for secure back-channel API communication.

In broad strokes, you want to:

1. Provision a server (or decide to colocate it on an existing server)
2. Deploy the code
3. Set environment variables to configure the database and other settings
4. Run migrations
5. Send traffic!

## Quick Start: Heroku

You can deploy AuthN to Heroku using free plans by simply filling in the configuration options here:

[![Configure and Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/keratin/authn/tree/master)

## Maximum Security

For maximum security, give AuthN dedicated SQL and Redis databases and be sure that all backups are strongly encrypted at rest. The credentials and accounts data encapsulated by AuthN should not be necessary for data warehousing or business intelligence, so try to minimize their exposure.

# Work in Progress

This work is actively in progress. Check back soon!

# COPYRIGHT & LICENSE

Copyright (c) 2016 Lance Ivy

Keratin AuthN is distributed under the terms of the GPLv3. See [LICENSE-GPLv3](LICENSE-GPLv3) for details.
