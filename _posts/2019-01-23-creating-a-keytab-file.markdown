---
layout: post
author: Owen Rumney
title: Creating a Kerberos Keytab file with ktutil
description: Steps that are required to create a Kerberos keytab file on Linux
tags: [security, kerberos, keytab, ktutil]
categories: [SysAdmin]
---

{% include callout.html type="info" content="NOTE: Creating a keytab is easy this is just to remind me." %}

## Assumptions

I'm assuming for anyone who is doing this that you have your `/etc/krb5.conf` in order and that isn't going to get in your way.

One thing you're going to want to know is what your permitted and default `enctypes` and the realm are from this file. In my case I'm going to use `aes128-cts-hmac-sha1-96` and my realm is `DPE.INTERNAL`.

## Creating the keytab file

To create the keytab file you're going to need `ktutil` (and a number of other `kxxxxxx` commands)

**RHEL/Centos**

```
sudo yum install krb5-workstation
```

**Ubuntu**

```
sudo apt-get install krb5-user
```

Now you have the required programs installed, you can create your keytab file using `ktutil`.

```shell
ktutil
```

This will present you with a prompt for you to add the entries in the keytab file

```shell
add_entry -password -p user@DPE.INTERNAL -k 1 -e aes256-cts-hmac-sha1-96
Password for user@DPE.INTERNAL: <enter password here>

write_kt user.keytab
quit
```

Breaking this down, we are saying that we want to add an entry to the keytab using a password for authentication.

The `-p` is the principal that we will be logging in as using the end file.

The `-k` refers to the Key Version Number which in some situations isn't really needed and is ignored (in Windows environment for example). You can get the current Key version number (kvno) by using the `kvno` command

```shell
kvno user@DPE.INTERNAL
user@DPE.INTERNAL: kvno = 1
```

The `-e` refers to the enctype mentioned earlier. This needs to be one of those that are permitted in your `krb5.conf` file so you're using an accepted and appropriate encryption.

## Testing the Key

We can now test the keytab for successfully login

```shell
kinit -kt user.keytab user@DPE.INTERNAL
```

This should exit normally, then we can check we've got a ticket using `klist`

```shell
klist

Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: user@DPE.INTERNAL

Valid Starting           Expires                Service principal
01/23/2019 14:27:28      01/24/2019 00:27:28    user@DPE.INTERNAL
```

To clear out the ticket, you can use `kdestroy`. This will remove all current authentications.
