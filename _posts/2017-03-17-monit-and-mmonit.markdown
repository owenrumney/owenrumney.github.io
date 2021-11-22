---
layout: post
author: Owen Rumney
title: Monit
tags: [monitoring, alerting, linux]
categories: [SysAdmin]
---

There are lots of monitoring and alerting tools out there and I'm sure everyone has there own preference on which they're going to use.

We have selected [monit](http://mmonit.com/monit/) for simple monitoring of disk space, tunnels and processes because its simple to setup and does exactly what we're asking it to do.

I particularly like DSL for defining which checks you want to perform.

As we're running monit on multiple machines, we're also evaluating [m/monit](http//mmonit.com) which centralises the monitoring of all the separate instances in a nice dashboard.

## Installing Monit

Our servers are Red Hat so we're not using `yum install monit` which will get you stated on on a Fedora machine. Equally the downloads page on the monit site will give you the quick and easy installation for other common platforms.

```
# create the install folder
sudo mkdir /opt/monit
cd /opt/monit

# get the latest release
wget http://mmonit.com/monit/dist/binary/5.21.0/monit-5.21.0-linux-x64.tar.gz

# unpack
tar -xvf monit-5.21.0-linux-x64.tar.gz
rm monit-5.21.0-linux-x64.tar.gz
mv monit-5.21.0 5.21.0
cd 5.21.0

# put some links in
sudo ln -s /opt/monit/5.21.0/conf/monitrc /etc/monitrc
sudo ln -s /opt/monit/5.21.0/bin/monit /usr/bin/monit
```

### Configuring Monit

Now the links are in we can configure the monit config file `monitrc`. The actually file has huge amounts of documentation; I'm going to limit this to the key points to get up and running

`sudo vi /etc/monitrc`

```
######################
## Monit control file
######################

set daemon  30   # check services at 30 seconds intervals

set logfile syslog

# configure the mmonit to report to
# set mmonit https://monit:monit@10.10.1.10:8443/collector

# configure email alerts (this is using AWS SES)
SET ALERT alerts@mycompany.com
SET MAILSERVER email-smtp.eu-west-1.amazonaws.com port 587
        username "" password ""
        using TLSV1
        with timeout 30 seconds

set mail-format {
from: my_ses_registered_email@mycompany.com
reply-to: my_ses_registered_email@mycompany.com
subject: $EVENT
message:
Monit
=====
Date:    $DATE
Host:    $HOST
Action:  $ACTION
Service: $SERVICE
Event:   $EVENT

Description:
============
$DESCRIPTION.
}

# configure the host connection
set httpd port 2812 and
  use address 0.0.0.0
  allow 0.0.0.0
  allow admin:monit # change the password


# configure checks - for example processes
CHECK PROCESS tunnel_somewhere MATCHING '.*?(autossh.*?(8081))'

# or disk space
CHECK DEVICE root WITH PATH /
  IF SPACE usage > 80% THEN ALERT

# or network connections
check network eth0 with interface eth0
  IF upload > 1 MB/s THEN ALERT
  IF total downloaded > 1 GB in last 2 hours THEN ALERT
  IF total downloaded > 10 GB in last day THEN ALERT
```

### Starting Monit

To start monit user

```
sudo monit start
```

If you make changes to `/etc/monitrc` then you can reload it with `sudo monit reload`
