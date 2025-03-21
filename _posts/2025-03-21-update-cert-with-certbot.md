---
layout: post
title: Scheduled update Lets Encrypt
date: 2025-03-21 00:00:00

description: Creating wild card certificates with LetsEncrypt
tags: [docker, certificates, home-assistant, letsencrypt]
categories: [containers]
twitter_text: Creating wild card certificates with LetsEncrypt
---

# The Brief

I run a number of containers on my Raspberry Pi for home assistant, monitoring etc and I use nginx as a reverse proxy to access them the internet. I have my domain `owenrumney.co.uk` and a subdomain of `home.owenrumney.co.uk` which I use a wildcard cert provided by Lets Encrypt.

[LetsEncrypt](https://letsencrypt.org/docs/) certificates last for 90 days and you get an email in decent time to tell you it needs renewing but I want to have it happen automatically on a schedule.

I'm using Gandi for my domain, so I need to [create a PAT token](https://api.gandi.net/docs/authentication/)

# The Solution

To do this I'm using [certbot](https://certbot.eff.org/) in a docker container that it run on a schedule.

There is a plugin available for certbot that works with Gandi to do the required steps creating the `TXT` entries to verify domain ownership.

## The Dockerfile

My Dockerfile is really simple, just uses certbot as the base image then installs the certbot plugin for Gandi

```dockerfile
FROM certbot/certbot

RUN pip3 install certbot-plugin-gandi

COPY cert.sh /cert.sh

ENTRYPOINT /cert.sh
```

## The cert script

I have a `cert.sh` script as the entry point which does all of the work. The gist of it is to run the certbot command with the gandi authenticate plugin and a mounted `gandi.ini` file which has a single entry for `dns_gandi_token=xxxxxxxxxxxxxxxxxxxxxxxx`.

The command creates a cert for the domain (in my case wild card) and email the finally copies the resultant cert to the mount. In my case the mount is the local nginx containers config.

```sh
#!/bin/sh -u

REGISTER_DOMAIN=$DOMAIN

certbot certonly --non-interactive \
        --agree-tos --authenticator dns-gandi \
        --dns-gandi-credentials /gandi/gandi.ini \
        -d ${REGISTER_DOMAIN} -m "${EMAIL}"

cp /etc/letsencrypt/live/${REGISTERED_DOMAIN}/* /certmount
```

## The Compose file

The compose file has a mount for my ini file and for the nginx config and simple env vars for the `DOMAIN` and `EMAIL`. The local `Dockerfile` from above is used for each run.

```
name: letsencrypt-renew

services:
  owencertbot:
    volumes:
      - ./gandi.ini:/gandi/gandi.ini:ro
      - ./../nginx/letsencrypt:/certmount
    environment:
      - DOMAIN=*.home.owenrumney.co.uk
      - EMAIL=owen@owenrumney.co.uk
    build: .
```

## The schedule

Finally, there is the schedule - I run this on the Raspberry pi from a cron job with the below schedule.

This runs a `docker compose up` at 3am on the 1st day of every second month

```
0 3 1 */2 * 
```

# Conclusion

It hasn't escaped me that I could just install the plugin and the certbot tool on my pi and run the renewal directly there in the cron schedule... its a combination of reasons.

- trying to do most things with Docker.. just because
- being able to move everything to a new pi or bigger with limited setup
- it was interesting
