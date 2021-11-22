---
layout: post
author: Owen Rumney
title: Using AWS Simple Email Service with Oozie in Cloudera
tags: [aws, cloudera, linux]
categories: [Big Data, Programming, Amazon Web Services]
---

I've moved to a new role where I will be doing a lot more "devops" type work which hopefully comes with more interesting subjects to start writing about.

## Oozie and AWS Simple Email Services

The Cloudera cluster I have started working on is hosted in AWS and has all the security bells and whistles turned on; Kerberos, TLS etc.

Recently a support ticket came my way where the `Email Action` in Oozie was failing, on top of this there was no notification around job success and the `Kill` action wasn't sending emails.... more than likely Oozie isn't correctly configured for email.

As mentioned before, we use TLS everywhere possible and want to use Amazon's Simple Email Service endpoint to relay the messages through. TLS SMTP isn't supported directly with Oozie so there is a requirement to put something in the middle. In this case, the something is going to be [postfix](http://www.postfix.org).

## Prerequisites

There are a number of details you'll need to get from AWS Management Console to get things set up.

In the AWS Management Console, navigate to the SES service and in the right hand side select SMTP settings. This is where you'll find the endpoint you need to use and you can use the `Create SMTP Credentials` button at the bottom of the page to create some keys. _ Keep in mind that although these keys look like normal AWS Access Keys, they are actually SMTP keys and are specifically for authenticating with AWS SES _

Now on the left choose `Email Addresses` and follow the process for validating an email address as required by SES.

## Installing and configuring postfix

These steps assume that you're running a `yum` flavoured Linux, its pretty much the same if you're working with Ubuntu if you interchange the package tooling.

First we need to install postfix

```
sudo yum install postfix -y
```

The configuration for postfix is in `/etc/postfix/main.cf`. This is where the relay to AWS SES is going to be happening.

There are a couple of tweaks that needed to be done in this file in addition to adding the relayhost section.

1. Change the `inet_protocols` value to only ipv4 - `inet_interfaces=ipv4`
2. Change the `inet_interfaces`, in my case I just commented out the whole line `#inet_interfaces=localhost`
3. Add the `smtp_tls_CAFile`, in my case we're using a pem file `smtp_tls_CAfile = /path/to/tls_cert.pem`

Now the `relayhost` section needs to be added so that it can forward to SES correctly.

In my case, I'm hosted in Ireland (`eu-west-1`) so my endpoint for SES is `email-smtp.eu-west-1.amazonaws.com`

```
relayhost = [email-smtp.eu-west-1.amazonaws.com]:25
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_use_tls = yes
smtp_tls_note_starttls_offer = yes
```

You can now save `main.cf`, we've finished with that.

You may have noticed the `smtp_sasl_password_maps` section pointing to a `sasl_passwd` file. We now need to create that. So create the file `/etc/postfix/sasl_passwd` and add the following using the credentials created for the SMTP user above.

```
[email-smtp.eu-west-1.amazonaws.com]:25 <smtpkey>:<smtpsecret>
```

You can now create the hash of this file, set the ownership and permissions then remove the new `sasl_passwd` file with the cleartext keys

```
sudo postmap hash:/etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl_passwd.db
sudo rm /etc/postfix/sasl_passwd
```

Now all you need to do is start the service `sudo postfix start`

## Configuring Oozie

You can configure Oozie in Cloudera Manager. Go to Oozie service -> Configuration. Set `oozie.email.smtp.host` and set the value to the IP address of the server you've installed postfix. (To keep it simple, I installed postfix on the Oozie server itself. I had to use the IP as Oozie doesn't like `localhost`)

Set the `oozie.email.from.address` you're going to be sending from to the value setup in SES Management Console email address page.

Restart Oozie and Hue then create a test workflow with an `Email Action` sending an email and run. All being well, the email will be sent and the workflow action will go green. Check the logs of the workflow if it doesn't work, it should be clear from there.
