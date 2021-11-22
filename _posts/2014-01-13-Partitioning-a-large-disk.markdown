---
title: Partitioning a large disk in RedHat
tags: [linux, red hat, infrastructure, hardware]
layout: post
author: Owen Rumney
categories: [SysAdmin]
---

For the project I am currently working on, we have an order for a Hadoop Appliance from our supplier to be placed in
the Mega Data Centre for processing all of our log files. The order is in, but with all the red tape its going to be
a while before it'll be up and running.

In order for this delay not to impact the project, we've been given dispensation to host a small cluster of machines
running Cloudera in one of the local server rooms. This will give us our processing capability while we wait for the
main appliance to be commissioned.

This week I've been installing the corporate approved build of Red Hat onto the old trader spec desktops that we've
managed to get our hands on. Its basically standard Red Hat Enterprise Server but with some slight modifications made
to harden it.

We have bought 3TB disks for the data storage in these boxes, given their size they're using GPT partition tables and
initially it's been difficult to get fdisk to partition the disks correctly. In the end,
the following steps were all that were needed to get things working and create the 3TB partition.

{% highlight sh  %}
\$ fdisk -l

# find the correct device name, in my case /dev/hdc

\$ parted /dev/hdc1
(parted) mklabel gpt
(parted) unit TB
(parted) mkpart primary 0 3

# check the partition

(parted) p
(parted) quit
\$ mkfs.ext4 /dev/hdc1
{% endhighlight %}
