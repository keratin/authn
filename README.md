Keratin AuthN is an authentication service that keeps you in control of the experience without forcing you to be an expert in web security.

## Your Data, Your Design

**Flexible Deployment:** bring your own database, deploy to your own infrastructure.

**API Driven:** optimized for custom, bespoke integrations.

**Open Source:** you will never be locked in.

## Secure By Default

**Vault Architecture:** your application never even sees passwords.

**Built from Standards:** adopts everything about OAuth 2.0 and OpenID Connect that is not related to a redirect-based (offsite) flow.

**Hardened Security:** care has been taken to avoid common and uncommon mistakes with best practice solutions.

## Grows With You

**Monolith Compatible:** even if your code is written as a monolith, you're still using services. They just happen to be written (and sometimes hosted) by other people.

**Services Ready:** provides essential authentication infrastructure for your service architecture.

# Features

* Signup
* Login
* Score-based password strength policies
* Username availability endpoint for real-time feedback
* Revokable sessions
* Password resets
* Active Account metrics by Day, Week, and Month
* Security hardening
* COMING SOON: Account Archival
* COMING SOON: Account Locking
* COMING SOON: Flagged Password Changes

Once the core roadmap is complete, I will be working on a Pro version with advanced features, maintenance and support commitments, and bug bounty policies. If you are interested in the direction of this project and would like to discuss roadmap, please drop by the Issues tracker.

# Integration

Your application is expected to host and manage any user-facing Frontend as well as deliver any appropriate emails. In some cases this means creating an endpoint with which AuthN can coordinate.

## Example: Signup

You will render a signup form as usual, but rely on a provided JavaScript library to register the username and password with AuthN in exchange for an ID Token (aka JWT session) that is submitted to your user signup endpoint instead.

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

You can deploy AuthN however you need. Here's what it requires:

* A Redis server for session tokens, ephemeral data, and activity metrics.
* A SQL server with ActiveRecord ORM support, like MySQL, PostgreSQL, or SQL Server.
* Network routing from your application's clients.
* Network routing to/from your application, for secure back-channel API communication.

In broad strokes, you want to:

1. Provision a server (or decide to colocate it on an existing server)
2. Deploy the code (COMING SOON: Docker container)
3. Set environment variables to configure the database and other settings
4. Run migrations
5. Send traffic!

## Maximum Security

For maximum security, give AuthN dedicated SQL and Redis databases and be sure that all backups are strongly encrypted at rest. The credentials and accounts data encapsulated by AuthN should not be necessary for data warehousing or business intelligence, so try to minimize their exposure.

# Work in Progress

This work is actively in progress. Check back soon!

If you're interested in kicking the tires and helping to prioritize the early roadmap, contact me. I expect to offer early bird adopter specials.

# COPYRIGHT & LICENSE

Copyright (c) 2016 Lance Ivy

Keratin AuthN is distributed under the terms of the GPLv3. See [LICENSE-GPLv3](LICENSE-GPLv3) for details.
