---
layout: post
author: Owen Rumney
title: Using yum history
tags: [linux]
categories: [SysAdmin]
---

I have been setting up a couple of Red Hat boxes and I need to have a cron task to mount a network share from an AD domain, copy the files then dismount.

In the past I have successfully accessed the network shares using a given set of credentials but I could not get it to work after install `samba-client` and `samba-common`.

My script on the new machine was the same as the script on the working machine so there had to be a discrepency on installed packages, step in `yum history`.

To get the history of yum commands use

```bash
yum history
```

which will give the output similar to;

![yum history outpu](../images/yum_history.png)

Thankfully, from the dates I was able to work out the point that I had done the install. From this point you can look at a specific item, for example;

```bash
yum history info 57
```

which will return more information about the command

![yum history info for id 5](../images/yum_history_info_57.png)
