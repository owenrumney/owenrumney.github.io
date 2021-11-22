---
layout: post
author: Owen Rumney
title: SFTP Connection Closed - password expired?
tags: [linux, sftp, users]
---

I've just had an interesting problem with an SFTP account that suddenly stopped working from a cron job. When the account was used directly from the bash prompt the response was simply Connection closed immediately.

Every thing was set up correctly as far as `authorized_keys` and `/etc/ssh/sshd_config` looked fine but the account wouldn't connect.

As I don't have the private key for the user that was connecting to the server, I created a new key pair and added the public key to the `authorized_keys` file in the users .ssh folder. Using the following command I got a response that was no more helpful;

    psftp logdrop@10.0.0.1 -i logdrop_pk.ppk

This gave the response;

    FATAL: Recieved unexpected end-of-file from SFTP Server

After a couple more checks on the server and no success I decided to try

    putty logdrop@10.0.0.1 -i logdrop_pk.ppk

This opened putty which connected but reported that the password for the user had expired and needed a new one. From here I was able to reset the password then go on the server and set

    passwd -x 0 logdrop

to ensure that the aging was deactivated.

So an interesting issue for a Friday afternoon.
